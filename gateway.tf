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
}

resource "awscc_bedrockagentcore_gateway" "agent_gateway" {
  count       = local.create_gateway ? 1 : 0
  name        = "${random_string.solution_prefix.result}-${var.gateway_name}"
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

  tags = var.gateway_tags
}

# IAM Role for Agent Gateway
resource "aws_iam_role" "gateway_role" {
  count = local.create_gateway && var.gateway_role_arn == null ? 1 : 0
  name  = "${random_string.solution_prefix.result}-bedrock-agent-gateway-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AssumeRolePolicy"
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock-agentcore.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })

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
resource "aws_iam_role_policy" "gateway_role_policy" {
  count = local.create_gateway && var.gateway_role_arn == null ? 1 : 0
  name  = "${random_string.solution_prefix.result}-bedrock-agent-gateway-policy"
  role  = aws_iam_role.gateway_role[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # Only include KMS permission when gateway_kms_key_arn is not null
      var.gateway_kms_key_arn != null ? [{
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [var.gateway_kms_key_arn]
      }] : [],
      [{
        Sid      = "GatewayReadPermissions"
        Effect   = "Allow"
        Action   = local.gateway_read_permissions
        Resource = "*"
      }],
      length(local.gateway_manage_permissions) > 0 ? [{
        Sid      = "GatewayManagePermissions"
        Effect   = "Allow"
        Action   = local.gateway_manage_permissions
        Resource = "*"
      }] : [],
      # Outbound OAuth permissions
      var.enable_oauth_outbound_auth ? [
        {
          Sid    = "GetWorkloadAccessToken"
          Effect = "Allow"
          Action = [
            "bedrock-agentcore:GetWorkloadAccessToken"
          ]
          Resource = [
            "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default",
            "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default/workload-identity/${random_string.solution_prefix.result}-${var.gateway_name}-*"
          ]
        },
        {
          Sid    = "GetResourceOauth2Token"
          Effect = "Allow"
          Action = [
            "bedrock-agentcore:GetResourceOauth2Token"
          ]
          Resource = var.oauth_credential_provider_arn != null ? [var.oauth_credential_provider_arn] : []
        },
        {
          Sid    = "GetSecretValueOauth"
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue"
          ]
          Resource = var.oauth_secret_arn != null ? [var.oauth_secret_arn] : []
        }
      ] : [],
      # Outbound API Key permissions
      var.enable_apikey_outbound_auth ? [
        {
          Sid    = "GetWorkloadAccessTokenApiKey"
          Effect = "Allow"
          Action = [
            "bedrock-agentcore:GetWorkloadAccessToken"
          ]
          Resource = [
            "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default",
            "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default/workload-identity/${random_string.solution_prefix.result}-${var.gateway_name}-*"
          ]
        },
        {
          Sid    = "GetResourceApiKey"
          Effect = "Allow"
          Action = [
            "bedrock-agentcore:GetResourceApiKey"
          ]
          Resource = concat(
            var.apikey_credential_provider_arn != null ? [var.apikey_credential_provider_arn] : [],
            var.apikey_secret_arn != null ? [var.apikey_secret_arn] : [],
            [
              "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default",
              "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default/workload-identity/${random_string.solution_prefix.result}-${var.gateway_name}-*"
            ],
            "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:token-vault/default"
          )
        },
        {
          Sid    = "GetSecretValueApiKey"
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue"
          ]
          Resource = var.apikey_secret_arn != null ? [var.apikey_secret_arn] : []
        }
      ] : [],
      # Lambda function invocation permissions
      local.has_lambda_targets ? [
        {
          Sid    = "AmazonBedrockAgentCoreGatewayLambdaProd"
          Effect = "Allow"
          Action = [
            "lambda:InvokeFunction"
          ]
          Resource = var.gateway_lambda_function_arns
        }
    ] : [])
  })
}
