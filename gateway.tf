# – Bedrock Agent Core Gateway –

locals {
  create_gateway = var.create_gateway

  # Gateway IAM permissions
  gateway_read_permissions = [
    "bedrock-agentcore:GetGatewayTarget",
    "bedrock-agentcore:GetGateway",
    "bedrock-agentcore:ListGateways",
    "bedrock-agentcore:ListGatewayTargets"
  ]

  gateway_create_permissions = var.gateway_allow_create_permissions ? [
    "bedrock-agentcore:CreateGateway",
    "bedrock-agentcore:CreateGatewayTarget"
  ] : []

  gateway_update_delete_permissions = var.gateway_allow_update_delete_permissions ? [
    "bedrock-agentcore:UpdateGateway",
    "bedrock-agentcore:UpdateGatewayTarget",
    "bedrock-agentcore:DeleteGateway",
    "bedrock-agentcore:DeleteGatewayTarget"
  ] : []

  # Combine permissions
  gateway_manage_permissions = concat(local.gateway_create_permissions, local.gateway_update_delete_permissions)

  # Lambda function access
  has_lambda_targets = length(var.gateway_lambda_function_arns) > 0

  # Gateway target access - needed for gateway targets created by this module
  has_gateway_targets = local.create_gateway && var.create_gateway_target

  # Interceptor Lambda access - needed for interceptor configurations
  has_interceptor_lambdas = length(var.gateway_interceptor_configurations) > 0
  interceptor_lambda_arns = [
    for config in var.gateway_interceptor_configurations :
    config.interceptor.lambda.arn
  ]
}

resource "awscc_bedrockagentcore_gateway" "agent_gateway" {
  count       = local.create_gateway ? 1 : 0
  name        = trimprefix("${local.solution_prefix}-${var.gateway_name}", "-")
  description = var.gateway_description
  role_arn    = var.gateway_role_arn != null ? var.gateway_role_arn : aws_iam_role.gateway_role[0].arn

  # Required fields
  authorizer_type = var.gateway_authorizer_type
  protocol_type   = var.gateway_protocol_type

  # Optional fields
  exception_level = var.gateway_exception_level
  kms_key_arn     = var.gateway_kms_key_arn

  # Conditional configuration blocks
  authorizer_configuration = var.gateway_authorizer_type == "CUSTOM_JWT" ? (
    local.create_user_pool ? local.gateway_authorizer_config :
    var.gateway_authorizer_configuration != null ? {
      custom_jwt_authorizer = {
        allowed_audience = var.gateway_authorizer_configuration.custom_jwt_authorizer.allowed_audience
        allowed_clients  = var.gateway_authorizer_configuration.custom_jwt_authorizer.allowed_clients
        discovery_url    = var.gateway_authorizer_configuration.custom_jwt_authorizer.discovery_url
      }
    } : null
  ) : null

  protocol_configuration = var.gateway_protocol_configuration != null ? {
    mcp = {
      instructions       = var.gateway_protocol_configuration.mcp.instructions
      search_type        = var.gateway_protocol_configuration.mcp.search_type
      supported_versions = var.gateway_protocol_configuration.mcp.supported_versions
    }
  } : null

  # Interceptor configurations for request/response interception
  interceptor_configurations = length(var.gateway_interceptor_configurations) > 0 ? [
    for config in var.gateway_interceptor_configurations : {
      interception_points = config.interception_points
      interceptor = {
        lambda = {
          arn = config.interceptor.lambda.arn
        }
      }
      input_configuration = config.input_configuration != null ? {
        pass_request_headers = config.input_configuration.pass_request_headers
      } : null
    }
  ] : null

  tags = var.gateway_tags
}

# IAM Role for Agent Gateway
data "aws_iam_policy_document" "gateway_role_assume_role" {
  statement {
    sid     = "AssumeRolePolicy"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

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

resource "aws_iam_role" "gateway_role" {
  count = local.create_gateway && var.gateway_role_arn == null ? 1 : 0
  name  = trimprefix("${local.solution_prefix}-bedrock-agent-gateway-role", "-")

  assume_role_policy = data.aws_iam_policy_document.gateway_role_assume_role.json

  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.gateway_tags
}

# Resource-based policy for Lambda functions in other accounts
resource "aws_lambda_permission" "cross_account_lambda_permissions" {
  for_each = { for idx, perm in var.gateway_cross_account_lambda_permissions : idx => perm }

  function_name = each.value.lambda_function_arn
  action        = "lambda:InvokeFunction"
  principal     = each.value.gateway_service_role_arn
  statement_id  = "LambdaAllowGatewayServiceRole-${each.key}"
  source_arn    = try(awscc_bedrockagentcore_gateway.agent_gateway[0].gateway_arn, null)

  depends_on = [
    awscc_bedrockagentcore_gateway.agent_gateway
  ]
}

# IAM Policy for Agent Gateway
data "aws_iam_policy_document" "gateway_role_policy" {
  count = local.create_gateway && var.gateway_role_arn == null ? 1 : 0

  # Only include KMS permission when gateway_kms_key_arn is not null
  dynamic "statement" {
    for_each = var.gateway_kms_key_arn != null ? [1] : []
    content {
      sid    = "GatewayKMSPermissions"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
      ]
      resources = [var.gateway_kms_key_arn]
    }
  }

  statement {
    sid       = "GatewayReadPermissions"
    effect    = "Allow"
    actions   = local.gateway_read_permissions
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(local.gateway_manage_permissions) > 0 ? [1] : []
    content {
      sid       = "GatewayManagePermissions"
      effect    = "Allow"
      actions   = local.gateway_manage_permissions
      resources = ["*"]
    }
  }

  # Outbound OAuth permissions
  dynamic "statement" {
    for_each = var.enable_oauth_outbound_auth ? [1] : []
    content {
      sid    = "GetWorkloadAccessToken"
      effect = "Allow"
      actions = [
        "bedrock-agentcore:GetWorkloadAccessToken",
      ]
      resources = [
        "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default",
        "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default/workload-identity/${trimprefix("${local.solution_prefix}-${var.gateway_name}-*", "-")}",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.enable_oauth_outbound_auth ? [1] : []
    content {
      sid    = "GetResourceOauth2Token"
      effect = "Allow"

      actions = [
        "bedrock-agentcore:GetResourceOauth2Token",
      ]

      resources = [
        "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default",
        "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default/workload-identity/${trimprefix("${local.solution_prefix}-${var.gateway_name}-*", "-")}",
        "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:token-vault/default",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.enable_oauth_outbound_auth && var.oauth_secret_arn != null ? [1] : []

    content {
      sid    = "GetSecretValueOauth"
      effect = "Allow"

      actions = [
        "secretsmanager:GetSecretValue",
      ]

      resources = [
        var.oauth_secret_arn
      ]
    }
  }

  # Outbound API Key permissions
  dynamic "statement" {
    for_each = var.enable_apikey_outbound_auth ? [1] : []
    content {
      sid    = "GetWorkloadAccessTokenApiKey"
      effect = "Allow"
      actions = [
        "bedrock-agentcore:GetWorkloadAccessToken",
      ]
      resources = [
        "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default",
        "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default/workload-identity/${trimprefix("${local.solution_prefix}-${var.gateway_name}-*", "-")}",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.enable_apikey_outbound_auth ? [1] : []
    content {
      sid    = "GetResourceApiKey"
      effect = "Allow"
      actions = [
        "bedrock-agentcore:GetResourceApiKey",
      ]
      resources = concat(
        var.apikey_credential_provider_arn != null ? [var.apikey_credential_provider_arn] : [],
        var.apikey_secret_arn != null ? [var.apikey_secret_arn] : [],
        [
          "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default",
          "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default/workload-identity/${trimprefix("${local.solution_prefix}-${var.gateway_name}-*", "-")}",
          "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:token-vault/default",
        ],
      )
    }
  }
  dynamic "statement" {
    for_each = var.enable_apikey_outbound_auth && var.apikey_secret_arn != null ? [1] : []
    content {
      sid    = "GetSecretValueApiKey"
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
      ]
      resources = [
        var.apikey_secret_arn,
      ]
    }
  }

  # Lambda function invocation permissions
  dynamic "statement" {
    for_each = local.has_lambda_targets ? [1] : []
    content {
      sid    = "AmazonBedrockAgentCoreGatewayLambdaProd"
      effect = "Allow"
      actions = [
        "lambda:InvokeFunction",
      ]
      resources = var.gateway_lambda_function_arns
    }
  }

  # Interceptor Lambda function invocation permissions
  dynamic "statement" {
    for_each = local.has_interceptor_lambdas ? [1] : []
    content {
      sid    = "GatewayInterceptorLambdaInvoke"
      effect = "Allow"
      actions = [
        "lambda:InvokeFunction",
      ]
      resources = local.interceptor_lambda_arns
    }
  }

  # Additional permissions needed for gateway targets if they're created by this module
  dynamic "statement" {
    for_each = local.has_gateway_targets ? [1] : []
    content {
      sid    = "GatewayTargetOperations"
      effect = "Allow"
      actions = [
        "bedrock-agentcore:CreateGatewayTarget",
        "bedrock-agentcore:DeleteGatewayTarget",
        "bedrock-agentcore:GetGatewayTarget",
        "bedrock-agentcore:UpdateGatewayTarget",
        "bedrock-agentcore:ListGatewayTargets",
      ]
      resources = [
        "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:gateway/*",
      ]
    }
  }

  # Additional permissions for Lambda targets if using LAMBDA target type with gateway_target
  dynamic "statement" {
    for_each = var.gateway_target_type == "LAMBDA" && var.gateway_target_lambda_config != null ? [1] : []
    content {
      sid    = "GatewayTargetLambdaInvoke"
      effect = "Allow"
      actions = [
        "lambda:InvokeFunction",
      ]
      resources = [
        var.gateway_target_lambda_config.lambda_arn,
      ]
    }
  }

  # Add S3 permissions for tool schemas stored in S3
  dynamic "statement" {
    for_each = (
      var.gateway_target_type == "LAMBDA" &&
      var.gateway_target_lambda_config != null &&
      var.gateway_target_lambda_config.tool_schema_type == "S3" &&
      var.gateway_target_lambda_config.s3_schema != null
    ) ? [1] : []

    content {
      sid    = "GatewayTargetS3Access"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion",
      ]
      resources = [
        "arn:aws:s3:::${split("/", replace(var.gateway_target_lambda_config.s3_schema.uri, "s3://", ""))[0]}/*",
      ]
    }
  }
}

resource "aws_iam_role_policy" "gateway_role_policy" {
  count = local.create_gateway && var.gateway_role_arn == null ? 1 : 0
  name  = trimprefix("${local.solution_prefix}-bedrock-agent-gateway-policy", "-")
  role  = aws_iam_role.gateway_role[0].name

  policy = data.aws_iam_policy_document.gateway_role_policy[0].json
}
