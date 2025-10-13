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
}

resource "awscc_bedrockagentcore_gateway" "agent_gateway" {
  count              = local.create_gateway ? 1 : 0
  name               = "${random_string.solution_prefix.result}_${var.gateway_name}"
  description        = var.gateway_description
  role_arn           = var.gateway_role_arn != null ? var.gateway_role_arn : aws_iam_role.gateway_role[0].arn
  
  # Required fields
  authorizer_type    = var.gateway_authorizer_type
  protocol_type      = var.gateway_protocol_type
  
  # Optional fields
  exception_level    = var.gateway_exception_level
  kms_key_arn        = var.gateway_kms_key_arn
  
  # Conditional configuration blocks
  authorizer_configuration = var.gateway_authorizer_configuration != null ? {
    custom_jwt_authorizer = {
      allowed_audience = var.gateway_authorizer_configuration.custom_jwt_authorizer.allowed_audience
      allowed_clients  = var.gateway_authorizer_configuration.custom_jwt_authorizer.allowed_clients
      discovery_url    = var.gateway_authorizer_configuration.custom_jwt_authorizer.discovery_url
    }
  } : null

  protocol_configuration = var.gateway_protocol_configuration != null ? {
    mcp = {
      instructions      = var.gateway_protocol_configuration.mcp.instructions
      search_type       = var.gateway_protocol_configuration.mcp.search_type
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

# IAM Policy for Agent Gateway
resource "aws_iam_role_policy" "gateway_role_policy" {
  count      = local.create_gateway && var.gateway_role_arn == null ? 1 : 0
  name       = "${random_string.solution_prefix.result}-bedrock-agent-gateway-policy"
  role       = aws_iam_role.gateway_role[0].name
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogStreams",
          "logs:CreateLogGroup"
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/gateways/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups"
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/gateways/*:log-stream:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Resource = "*"
        Action = "cloudwatch:PutMetricData"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "bedrock-agentcore"
          }
        }
      },
      {
        Sid = "GetGatewayAccessToken"
        Effect = "Allow"
        Action = [
          "bedrock-agentcore:GetWorkloadAccessToken",
          "bedrock-agentcore:GetWorkloadAccessTokenForJWT",
          "bedrock-agentcore:GetWorkloadAccessTokenForUserId"
        ]
        Resource = [
          "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default",
          "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default/workload-identity/${random_string.solution_prefix.result}_${var.gateway_name}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = var.gateway_kms_key_arn != null ? [var.gateway_kms_key_arn] : ["*"]
        Condition = var.gateway_kms_key_arn == null ? {
          StringEquals = {
            "kms:ViaService" = "bedrock-agentcore.${data.aws_region.current.region}.amazonaws.com"
          }
        } : null
      },
      {
        Sid = "GatewayReadPermissions"
        Effect = "Allow"
        Action = local.gateway_read_permissions
        Resource = "*"
      },
      length(local.gateway_manage_permissions) > 0 ? {
        Sid = "GatewayManagePermissions"
        Effect = "Allow"
        Action = local.gateway_manage_permissions
        Resource = "*"
      } : null
    ]
  })
}
