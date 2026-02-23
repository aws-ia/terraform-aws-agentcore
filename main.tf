# – Bedrock Agent Core Runtime –
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "random_string" "solution_prefix" {
  count   = var.use_solution_prefix ? 1 : 0
  length  = 4
  special = false
  upper   = false
  numeric = false
}

locals {
  create_runtime  = var.create_runtime
  solution_prefix = var.use_solution_prefix ? random_string.solution_prefix[0].result : ""
  # Sanitize runtime name to ensure it follows the regex pattern ^[a-zA-Z][a-zA-Z0-9_]{0,47}$
  sanitized_runtime_name = replace(var.runtime_name, "-", "_")
}

# IAM Policy for creating the Service-Linked Role
data "aws_iam_policy_document" "service_linked_role" {
  count = local.create_runtime ? 1 : 0

  statement {
    sid    = "CreateBedrockAgentCoreIdentityServiceLinkedRolePermissions"
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole"
    ]
    resources = [
      "arn:aws:iam::*:role/aws-service-role/runtime-identity.bedrock-agentcore.amazonaws.com/AWSServiceRoleForBedrockAgentCoreRuntimeIdentity"
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values = [
        "runtime-identity.bedrock-agentcore.amazonaws.com"
      ]
    }
  }
}

# Container-based runtime
resource "awscc_bedrockagentcore_runtime" "agent_runtime_container" {
  count              = local.create_runtime && var.runtime_artifact_type == "container" ? 1 : 0
  agent_runtime_name = trimprefix("${local.solution_prefix}_${local.sanitized_runtime_name}", "_")
  description        = var.runtime_description
  role_arn           = var.runtime_role_arn != null ? var.runtime_role_arn : aws_iam_role.runtime_role[0].arn

  # Explicit dependency to avoid race conditions with IAM role creation
  # Include the time_sleep resource to ensure IAM role propagation
  depends_on = [
    aws_iam_role.runtime_role,
    aws_iam_role_policy.runtime_role_policy,
    aws_iam_role_policy.runtime_slr_policy,
    time_sleep.iam_role_propagation
  ]

  agent_runtime_artifact = {
    container_configuration = {
      container_uri = var.runtime_container_uri
    }
  }

  network_configuration = {
    network_mode = var.runtime_network_mode
    network_mode_config = var.runtime_network_mode == "VPC" ? {
      security_groups = var.runtime_network_configuration.security_groups
      subnets         = var.runtime_network_configuration.subnets
    } : null
  }

  environment_variables = var.runtime_environment_variables

  authorizer_configuration = var.runtime_authorizer_configuration != null ? {
    custom_jwt_authorizer = {
      allowed_audience = var.runtime_authorizer_configuration.custom_jwt_authorizer.allowed_audience
      allowed_clients  = var.runtime_authorizer_configuration.custom_jwt_authorizer.allowed_clients
      discovery_url    = var.runtime_authorizer_configuration.custom_jwt_authorizer.discovery_url
    }
  } : null

  lifecycle_configuration = var.runtime_lifecycle_configuration != null ? {
    idle_runtime_session_timeout = var.runtime_lifecycle_configuration.idle_runtime_session_timeout
    max_lifetime                 = var.runtime_lifecycle_configuration.max_lifetime
  } : null

  request_header_configuration = var.runtime_request_header_configuration != null ? {
    request_header_allowlist = var.runtime_request_header_configuration.request_header_allowlist
  } : null

  protocol_configuration = var.runtime_protocol_configuration
  tags                   = var.runtime_tags
}

# Code-based runtime
resource "awscc_bedrockagentcore_runtime" "agent_runtime_code" {
  count              = local.create_runtime && var.runtime_artifact_type == "code" ? 1 : 0
  agent_runtime_name = trimprefix("${local.solution_prefix}_${local.sanitized_runtime_name}", "_")
  description        = var.runtime_description
  role_arn           = var.runtime_role_arn != null ? var.runtime_role_arn : aws_iam_role.runtime_role[0].arn

  # Explicit dependency to avoid race conditions with IAM role creation
  # Include the time_sleep resource to ensure IAM role propagation
  depends_on = [
    aws_iam_role.runtime_role,
    aws_iam_role_policy.runtime_role_policy,
    aws_iam_role_policy.runtime_slr_policy,
    time_sleep.iam_role_propagation
  ]

  agent_runtime_artifact = {
    code_configuration = {
      code = {
        s3 = {
          bucket     = var.runtime_code_s3_bucket
          prefix     = var.runtime_code_s3_prefix
          version_id = var.runtime_code_s3_version_id
        }
      }
      entry_point = var.runtime_code_entry_point
      runtime     = var.runtime_code_runtime_type
    }
  }

  network_configuration = {
    network_mode = var.runtime_network_mode
    network_mode_config = var.runtime_network_mode == "VPC" ? {
      security_groups = var.runtime_network_configuration.security_groups
      subnets         = var.runtime_network_configuration.subnets
    } : null
  }

  environment_variables = var.runtime_environment_variables

  authorizer_configuration = var.runtime_authorizer_configuration != null ? {
    custom_jwt_authorizer = {
      allowed_audience = var.runtime_authorizer_configuration.custom_jwt_authorizer.allowed_audience
      allowed_clients  = var.runtime_authorizer_configuration.custom_jwt_authorizer.allowed_clients
      discovery_url    = var.runtime_authorizer_configuration.custom_jwt_authorizer.discovery_url
    }
  } : null

  protocol_configuration = var.runtime_protocol_configuration
  tags                   = var.runtime_tags
}

# Reference for agent runtime ID
locals {
  agent_runtime_id      = var.runtime_artifact_type == "container" ? awscc_bedrockagentcore_runtime.agent_runtime_container[0].agent_runtime_id : awscc_bedrockagentcore_runtime.agent_runtime_code[0].agent_runtime_id
  agent_runtime_version = var.runtime_artifact_type == "container" ? awscc_bedrockagentcore_runtime.agent_runtime_container[0].agent_runtime_version : awscc_bedrockagentcore_runtime.agent_runtime_code[0].agent_runtime_version
}

# IAM Role for Agent Runtime
data "aws_iam_policy_document" "runtime_role_assume_role_policy" {
  count = local.create_runtime && var.runtime_role_arn == null ? 1 : 0

  statement {
    sid    = "AssumeRolePolicy"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["bedrock-agentcore.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

resource "aws_iam_role" "runtime_role" {
  count = local.create_runtime && var.runtime_role_arn == null ? 1 : 0
  name  = trimprefix("${local.solution_prefix}-bedrock-agent-runtime-role", "-")

  assume_role_policy = data.aws_iam_policy_document.runtime_role_assume_role_policy[0].json

  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.runtime_tags
}

# IAM Policy for Agent Runtime
# Attach SLR policy to runtime role if created
resource "aws_iam_role_policy" "runtime_slr_policy" {
  count  = local.create_runtime && var.runtime_role_arn == null ? 1 : 0
  name   = trimprefix("${local.solution_prefix}-bedrock-agent-runtime-slr-policy", "-")
  role   = aws_iam_role.runtime_role[0].name
  policy = data.aws_iam_policy_document.service_linked_role[0].json
}

# Add a time delay to ensure IAM role propagation
resource "time_sleep" "iam_role_propagation" {
  count           = local.create_runtime && var.runtime_role_arn == null ? 1 : 0
  depends_on      = [aws_iam_role.runtime_role, aws_iam_role_policy.runtime_role_policy, aws_iam_role_policy.runtime_slr_policy]
  create_duration = "20s"
}

data "aws_iam_policy_document" "runtime_role_policy" {
  count = local.create_runtime && var.runtime_role_arn == null ? 1 : 0

  statement {
    sid    = "ECRImageAccess"
    effect = "Allow"

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      coalesce(
        var.runtime_container_ecr_arn,
        "arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/*",
      ),
    ]
  }

  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"

    actions = [
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*",
    ]
  }

  statement {
    sid    = "CloudWatchLogsDescribeGroups"
    effect = "Allow"

    actions = [
      "logs:DescribeLogGroups",
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*",
    ]
  }

  statement {
    sid    = "CloudWatchLogsWriteAccess"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*:log-stream:*",
    ]
  }

  statement {
    sid    = "ECRTokenAccess"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "XRayAccess"
    effect = "Allow"

    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudWatchMetrics"
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["bedrock-agentcore"]
    }
  }

  statement {
    sid    = "GetAgentAccessToken"
    effect = "Allow"

    actions = [
      "bedrock-agentcore:GetWorkloadAccessToken",
      "bedrock-agentcore:GetWorkloadAccessTokenForJWT",
      "bedrock-agentcore:GetWorkloadAccessTokenForUserId",
    ]

    resources = [
      "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default",
      "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default/workload-identity/${trimprefix("${local.solution_prefix}_${local.sanitized_runtime_name}-*", "_")}",
    ]
  }

  statement {
    sid    = "BedrockModelInvocation"
    effect = "Allow"

    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]

    resources = [
      "arn:aws:bedrock:*::foundation-model/*",
      "arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*",
    ]
  }
}

data "aws_iam_policy_document" "runtime_role_policy_merged" {
  count = local.create_runtime && var.runtime_role_arn == null ? 1 : 0

  source_policy_documents = compact([
    data.aws_iam_policy_document.runtime_role_policy[0].json,
    var.runtime_additional_iam_policies,
  ])
}

resource "aws_iam_role_policy" "runtime_role_policy" {
  count = local.create_runtime && var.runtime_role_arn == null ? 1 : 0
  name  = trimprefix("${local.solution_prefix}-bedrock-agent-runtime-policy", "-")
  role  = aws_iam_role.runtime_role[0].name

  policy = data.aws_iam_policy_document.runtime_role_policy_merged[0].json
}

# – Bedrock Agent Core Runtime Endpoint –

locals {
  create_runtime_endpoint = var.create_runtime_endpoint
  # Sanitize runtime endpoint name to ensure it follows the regex pattern ^[a-zA-Z][a-zA-Z0-9_]{0,47}$
  sanitized_runtime_endpoint_name = replace(var.runtime_endpoint_name, "-", "_")
}

resource "awscc_bedrockagentcore_runtime_endpoint" "agent_runtime_endpoint" {
  count                 = local.create_runtime_endpoint ? 1 : 0
  name                  = trimprefix("${local.solution_prefix}_${local.sanitized_runtime_endpoint_name}", "_")
  description           = var.runtime_endpoint_description
  agent_runtime_id      = coalesce(var.runtime_endpoint_agent_runtime_id, local.agent_runtime_id)
  agent_runtime_version = var.runtime_endpoint_agent_runtime_version_ignore ? null : coalesce(var.runtime_endpoint_agent_runtime_version, local.agent_runtime_version)
  tags                  = var.runtime_endpoint_tags
}
