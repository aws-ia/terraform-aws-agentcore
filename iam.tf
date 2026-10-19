# =============================================================================
# IAM RESOURCES
# =============================================================================
# This file contains all IAM-related resources including:
# - IAM policy documents (data sources)
# - IAM roles
# - IAM policies
# - IAM role policy attachments
# - IAM propagation delays

# =============================================================================
# RUNTIME IAM
# =============================================================================

# Runtime assume role policy
data "aws_iam_policy_document" "runtime_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["bedrock-agentcore.amazonaws.com"]
    }
  }
}

# =============================================================================
# RUNTIME IAM
# =============================================================================

# Runtime IAM roles
resource "aws_iam_role" "runtime" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if config.execution_role_arn == null
  }

  name                 = "${var.project_prefix}-${each.key}-runtime"
  assume_role_policy   = data.aws_iam_policy_document.runtime_assume_role.json
  tags                 = local.merged_tags
}

# Wait for IAM role propagation
resource "time_sleep" "iam_role_propagation" {
  for_each = aws_iam_role.runtime

  create_duration = "10s"

  depends_on = [aws_iam_role_policy.runtime]
}

resource "aws_iam_role_policy" "runtime" {
  for_each = aws_iam_role.runtime

  role   = each.value.name
  policy = data.aws_iam_policy_document.runtime_policy[each.key].json
}

data "aws_iam_policy_document" "runtime_policy" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if config.execution_role_arn == null
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/bedrock/agentcore/*"]
  }

  statement {
    sid    = "AllowXRayTracing"
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudWatchMetrics"
    effect = "Allow"
    actions = ["cloudwatch:PutMetricData"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["AWS/Bedrock/AgentCore"]
    }
  }

  statement {
    sid    = "AllowBedrockModelInvocation"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowWorkloadIdentityTokenManagement"
    effect = "Allow"
    actions = [
      "bedrock-agentcore:GetWorkloadIdentityToken",
      "bedrock-agentcore:RefreshWorkloadIdentityToken"
    ]
    resources = ["*"]
  }

  # Workload access tokens for the runtime's own workload identity
  # (AgentCore Identity creates it as <runtime name>-<id> in the default directory)
  statement {
    sid    = "AllowWorkloadAccessToken"
    effect = "Allow"
    actions = [
      "bedrock-agentcore:GetWorkloadAccessToken",
      "bedrock-agentcore:GetWorkloadAccessTokenForJWT",
      "bedrock-agentcore:GetWorkloadAccessTokenForUserId"
    ]
    resources = [
      "arn:aws:bedrock-agentcore:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default",
      "arn:aws:bedrock-agentcore:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default/workload-identity/${each.key}-*"
    ]
  }

  # CODE: S3 read permissions
  dynamic "statement" {
    for_each = each.value.source_type == "CODE" ? [1] : []
    content {
      sid    = "AllowS3Read"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion"
      ]
      resources = ["${aws_s3_bucket.runtime[each.key].arn}/*"]
    }
  }

  # CONTAINER: ECR pull permissions
  dynamic "statement" {
    for_each = each.value.source_type == "CONTAINER" ? [1] : []
    content {
      sid    = "AllowECRPull"
      effect = "Allow"
      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ]
      resources = ["*"]
    }
  }
}

# CodeBuild IAM roles for CONTAINER runtimes
resource "aws_iam_role" "codebuild_container" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if config.source_type == "CONTAINER" && config.container_source_path != null
  }

  name = "${var.project_prefix}-${each.key}-codebuild-container"

  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
  tags               = local.merged_tags
}

# CodeBuild IAM roles for CODE runtimes
resource "aws_iam_role" "codebuild_code" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if config.source_type == "CODE" && config.code_source_path != null
  }

  name = "${var.project_prefix}-${each.key}-codebuild-code"

  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
  tags               = local.merged_tags
}

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "codebuild_container" {
  for_each = aws_iam_role.codebuild_container

  role   = each.value.name
  policy = data.aws_iam_policy_document.codebuild_container_policy[each.key].json
}

resource "aws_iam_role_policy" "codebuild_code" {
  for_each = aws_iam_role.codebuild_code

  role   = each.value.name
  policy = data.aws_iam_policy_document.codebuild_code_policy[each.key].json
}

# Wait for CodeBuild IAM policy propagation
resource "time_sleep" "codebuild_iam_propagation" {
  for_each = merge(
    { for k, v in aws_iam_role.codebuild_container : k => v },
    { for k, v in aws_iam_role.codebuild_code : k => v }
  )

  create_duration = "10s"

  depends_on = [
    aws_iam_role_policy.codebuild_container,
    aws_iam_role_policy.codebuild_code
  ]
}

data "aws_iam_policy_document" "codebuild_container_policy" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if config.source_type == "CONTAINER" && config.container_source_path != null
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.project_prefix}-${each.key}-container*"]
  }

  statement {
    sid    = "AllowS3Read"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = ["${aws_s3_bucket.runtime[each.key].arn}/*"]
  }

  statement {
    sid       = "AllowECRAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowECRPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:DescribeImages"
    ]
    resources = [aws_ecr_repository.runtime[each.key].arn]
  }
}

data "aws_iam_policy_document" "codebuild_code_policy" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if config.source_type == "CODE" && config.code_source_path != null
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.project_prefix}-${each.key}-code*"]
  }

  statement {
    sid    = "AllowS3ReadWrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:HeadObject"
    ]
    resources = ["${aws_s3_bucket.runtime[each.key].arn}/*"]
  }
}

# =============================================================================
# GATEWAY IAM
# =============================================================================

resource "aws_iam_role" "gateway" {
  for_each = {
    for name, config in var.gateways :
    name => config
    if config.role_arn == null
  }

  name               = "${var.project_prefix}-${each.key}-gateway"
  assume_role_policy = data.aws_iam_policy_document.gateway_assume_role.json
  tags               = local.merged_tags
}

data "aws_iam_policy_document" "gateway_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["bedrock-agentcore.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "gateway_role_policy" {
  for_each = aws_iam_role.gateway

  role   = each.value.name
  policy = data.aws_iam_policy_document.gateway_policy[each.key].json
}

# Wait for IAM policy propagation
resource "time_sleep" "gateway_iam_policy_propagation" {
  for_each = aws_iam_role.gateway

  create_duration = "15s"

  depends_on = [aws_iam_role_policy.gateway_role_policy]
}

data "aws_iam_policy_document" "gateway_policy" {
  for_each = {
    for name, config in var.gateways :
    name => config
    if config.role_arn == null
  }

  statement {
    sid    = "AllowBedrockModelInvocation"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowWorkloadIdentityTokenManagement"
    effect = "Allow"
    actions = [
      "bedrock-agentcore:GetWorkloadIdentityToken",
      "bedrock-agentcore:RefreshWorkloadIdentityToken"
    ]
    resources = ["*"]
  }

  # Allow Lambda invocation for gateway targets
  dynamic "statement" {
    for_each = length([for k, v in var.gateway_targets : v if v.gateway_name == each.key && v.type == "LAMBDA"]) > 0 ? [1] : []
    content {
      sid       = "AllowLambdaInvocation"
      effect    = "Allow"
      actions   = ["lambda:InvokeFunction"]
      resources = [
        for k, v in var.gateway_targets :
        v.lambda_config.lambda_arn
        if v.gateway_name == each.key && v.type == "LAMBDA"
      ]
    }
  }

  # Policy engine: read the engine configuration and evaluate policies
  # (required before a policy engine can be attached to the gateway)
  dynamic "statement" {
    for_each = each.value.policy_engine_configuration != null ? [1] : []
    content {
      sid       = "AllowPolicyEngineConfiguration"
      effect    = "Allow"
      actions   = ["bedrock-agentcore:GetPolicyEngine"]
      resources = [local.gateway_policy_engine_arns[each.key]]
    }
  }

  dynamic "statement" {
    for_each = each.value.policy_engine_configuration != null ? [1] : []
    content {
      sid    = "AllowPolicyEngineAuthorization"
      effect = "Allow"
      actions = [
        "bedrock-agentcore:AuthorizeAction",
        "bedrock-agentcore:PartiallyAuthorizeActions"
      ]
      resources = [
        local.gateway_policy_engine_arns[each.key],
        "arn:aws:bedrock-agentcore:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:gateway/${each.key}-*"
      ]
    }
  }

  # Temporal (Dogwood) policies: the gateway mints a workload access token to
  # propagate the caller's policy session
  dynamic "statement" {
    for_each = each.value.policy_engine_configuration != null ? [1] : []
    content {
      sid       = "AllowPolicySessionWorkloadIdentity"
      effect    = "Allow"
      actions   = ["bedrock-agentcore:GetWorkloadAccessToken"]
      resources = [
        "arn:aws:bedrock-agentcore:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default",
        "arn:aws:bedrock-agentcore:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default/workload-identity/${each.key}-*"
      ]
    }
  }
}

# =============================================================================
# MEMORY IAM
# =============================================================================

resource "aws_iam_role" "memory" {
  for_each = {
    for name, config in var.memories :
    name => config
    if config.execution_role_arn == null && length(config.strategies) > 0
  }

  name               = "${var.project_prefix}-${each.key}-memory"
  assume_role_policy = data.aws_iam_policy_document.memory_assume_role.json
  tags               = local.merged_tags
}

data "aws_iam_policy_document" "memory_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["bedrock-agentcore.amazonaws.com"]
    }
  }
}

# Wait for IAM role propagation
resource "time_sleep" "memory_iam_role_propagation" {
  for_each = aws_iam_role.memory

  create_duration = "10s"

  depends_on = [aws_iam_role.memory]
}

# =============================================================================
# BROWSER IAM
# =============================================================================

resource "aws_iam_role" "browser" {
  for_each = {
    for name, config in var.browsers :
    name => config
    if config.execution_role_arn == null
  }

  name               = "${var.project_prefix}-${each.key}-browser"
  assume_role_policy = data.aws_iam_policy_document.browser_assume_role.json
  tags               = local.merged_tags
}

data "aws_iam_policy_document" "browser_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["bedrock-agentcore.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "browser_role_policy" {
  for_each = aws_iam_role.browser

  role   = each.value.name
  policy = data.aws_iam_policy_document.browser_policy[each.key].json
}

# Wait for IAM role propagation
resource "time_sleep" "browser_iam_role_propagation" {
  for_each = aws_iam_role.browser

  create_duration = "30s"

  depends_on = [aws_iam_role_policy.browser_role_policy]
}

data "aws_iam_policy_document" "browser_policy" {
  for_each = {
    for name, config in var.browsers :
    name => config
    if config.execution_role_arn == null
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/bedrock/agentcore/*"]
  }

  dynamic "statement" {
    for_each = each.value.recording_enabled ? [1] : []
    content {
      sid    = "AllowS3Recording"
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ]
      resources = ["arn:aws:s3:::${each.value.recording_config.bucket}/${each.value.recording_config.prefix}*"]
    }
  }
}

# =============================================================================
# CODE INTERPRETER IAM
# =============================================================================

resource "aws_iam_role" "code_interpreter" {
  for_each = {
    for name, config in var.code_interpreters :
    name => config
    if config.execution_role_arn == null
  }

  name               = "${var.project_prefix}-${each.key}-code-interpreter"
  assume_role_policy = data.aws_iam_policy_document.code_interpreter_assume_role.json
  tags               = local.merged_tags
}

data "aws_iam_policy_document" "code_interpreter_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["bedrock-agentcore.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "code_interpreter_role_policy" {
  for_each = aws_iam_role.code_interpreter

  role   = each.value.name
  policy = data.aws_iam_policy_document.code_interpreter_policy[each.key].json
}

# Wait for IAM role propagation
resource "time_sleep" "code_interpreter_iam_role_propagation" {
  for_each = aws_iam_role.code_interpreter

  create_duration = "30s"

  depends_on = [aws_iam_role_policy.code_interpreter_role_policy]
}

data "aws_iam_policy_document" "code_interpreter_policy" {
  for_each = {
    for name, config in var.code_interpreters :
    name => config
    if config.execution_role_arn == null
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/bedrock/agentcore/*"]
  }
}

# =============================================================================
# AGENT REGISTRY IAM (publishers)
# =============================================================================
# A publisher is the pipeline or principal that writes registry records and
# submits them for approval. The managed policy can be attached to an existing
# pipeline role; a dedicated role is created when trusted principals or
# services are given.

data "aws_iam_policy_document" "registry_publisher_policy" {
  for_each = local.registry_publisher_policies

  statement {
    sid    = "AllowRegistryRead"
    effect = "Allow"
    actions = [
      "agent-registry:GetRegistry",
      "agent-registry:ListRegistryRecords"
    ]
    resources = [awscc_agentregistry_registry.registry[each.key].registry_arn]
  }

  statement {
    sid    = "AllowRegistryRecordPublishing"
    effect = "Allow"
    actions = [
      "agent-registry:CreateRegistryRecord",
      "agent-registry:GetRegistryRecord",
      "agent-registry:UpdateRegistryRecord",
      "agent-registry:DeleteRegistryRecord",
      "agent-registry:SubmitRegistryRecordForApproval",
      "agent-registry:TagResource",
      "agent-registry:UntagResource",
      "agent-registry:ListTagsForResource"
    ]
    resources = [
      awscc_agentregistry_registry.registry[each.key].registry_arn,
      "${awscc_agentregistry_registry.registry[each.key].registry_arn}/record/*"
    ]
  }

  # Optional curator permission: approve, reject or deprecate records
  dynamic "statement" {
    for_each = each.value.publisher.allow_approval ? [1] : []
    content {
      sid       = "AllowRegistryRecordApproval"
      effect    = "Allow"
      actions   = ["agent-registry:UpdateRegistryRecordStatus"]
      resources = ["${awscc_agentregistry_registry.registry[each.key].registry_arn}/record/*"]
    }
  }
}

resource "aws_iam_policy" "registry_publisher" {
  for_each = local.registry_publisher_policies

  name        = "${var.project_prefix}-${each.key}-registry-publisher"
  description = "Write and submit AWS Agent Registry records in registry ${each.key}"
  policy      = data.aws_iam_policy_document.registry_publisher_policy[each.key].json
  tags        = local.merged_tags
}

data "aws_iam_policy_document" "registry_publisher_assume_role" {
  for_each = local.registry_publisher_roles

  dynamic "statement" {
    for_each = length(each.value.publisher.trusted_principal_arns) > 0 ? [1] : []
    content {
      actions = ["sts:AssumeRole"]
      effect  = "Allow"
      principals {
        type        = "AWS"
        identifiers = each.value.publisher.trusted_principal_arns
      }
    }
  }

  dynamic "statement" {
    for_each = length(each.value.publisher.trusted_services) > 0 ? [1] : []
    content {
      actions = ["sts:AssumeRole"]
      effect  = "Allow"
      principals {
        type        = "Service"
        identifiers = each.value.publisher.trusted_services
      }
    }
  }
}

resource "aws_iam_role" "registry_publisher" {
  for_each = local.registry_publisher_roles

  name               = "${var.project_prefix}-${each.key}-registry-publisher"
  assume_role_policy = data.aws_iam_policy_document.registry_publisher_assume_role[each.key].json
  tags               = local.merged_tags
}

resource "aws_iam_role_policy_attachment" "registry_publisher" {
  for_each = aws_iam_role.registry_publisher

  role       = each.value.name
  policy_arn = aws_iam_policy.registry_publisher[each.key].arn
}
