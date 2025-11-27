# – Bedrock Agent Core Code Interpreter Custom –

locals {
  create_code_interpreter = var.create_code_interpreter
  # Sanitize code interpreter name to ensure it follows the regex pattern ^[a-zA-Z][a-zA-Z0-9_]{0,47}$
  sanitized_code_interpreter_name = replace(var.code_interpreter_name, "-", "_")

  # Data Plane Permissions

  # Permissions to manage a specific code interpreter session
  code_interpreter_session_perms = [
    "bedrock-agentcore:GetCodeInterpreterSession",
    "bedrock-agentcore:ListCodeInterpreterSessions",
    "bedrock-agentcore:StartCodeInterpreterSession",
    "bedrock-agentcore:StopCodeInterpreterSession"
  ]

  # Permissions to invoke a code interpreter
  code_interpreter_invoke_perms = ["bedrock-agentcore:InvokeCodeInterpreter"]

  # Control Plane Permissions

  # Grants control plane operations to manage the code interpreter (CRUD)
  code_interpreter_admin_perms = [
    "bedrock-agentcore:CreateCodeInterpreter",
    "bedrock-agentcore:DeleteCodeInterpreter",
    "bedrock-agentcore:GetCodeInterpreter",
    "bedrock-agentcore:ListCodeInterpreters"
  ]

  # Permissions for reading code interpreter information
  code_interpreter_read_perms = [
    "bedrock-agentcore:GetCodeInterpreter",
    "bedrock-agentcore:GetCodeInterpreterSession"
  ]

  # Permissions for listing code interpreter resources
  code_interpreter_list_perms = [
    "bedrock-agentcore:ListCodeInterpreters",
    "bedrock-agentcore:ListCodeInterpreterSessions"
  ]

  # Permissions for using code interpreter functionality
  code_interpreter_use_perms = [
    "bedrock-agentcore:StartCodeInterpreterSession",
    "bedrock-agentcore:InvokeCodeInterpreter",
    "bedrock-agentcore:StopCodeInterpreterSession"
  ]

  # Combined permissions for full access
  code_interpreter_full_access_perms = distinct(concat(
    local.code_interpreter_session_perms,
    local.code_interpreter_invoke_perms,
    local.code_interpreter_admin_perms
  ))

  # Policy documents

  # Code interpreter full access policy document
  code_interpreter_full_access_policy_doc = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BedrockAgentCodeInterpreterFullAccess"
        Effect   = "Allow"
        Action   = local.code_interpreter_full_access_perms
        Resource = "arn:aws:bedrock-agentcore:*:*:code-interpreter/*"
      }
    ]
  }

  # Code interpreter session policy document
  code_interpreter_session_policy_doc = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BedrockAgentCodeInterpreterSession"
        Effect   = "Allow"
        Action   = local.code_interpreter_session_perms
        Resource = "arn:aws:bedrock-agentcore:*:*:code-interpreter/*"
      }
    ]
  }

  # Code interpreter invoke policy document
  code_interpreter_invoke_policy_doc = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BedrockAgentCodeInterpreterInvoke"
        Effect   = "Allow"
        Action   = local.code_interpreter_invoke_perms
        Resource = "arn:aws:bedrock-agentcore:*:*:code-interpreter/*"
      }
    ]
  }

  # Code interpreter admin policy document
  code_interpreter_admin_policy_doc = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BedrockAgentCodeInterpreterAdmin"
        Effect   = "Allow"
        Action   = local.code_interpreter_admin_perms
        Resource = "arn:aws:bedrock-agentcore:*:*:code-interpreter/*"
      }
    ]
  }

  # Code interpreter read policy document
  code_interpreter_read_policy_doc = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BedrockAgentCodeInterpreterRead"
        Effect   = "Allow"
        Action   = local.code_interpreter_read_perms
        Resource = "arn:aws:bedrock-agentcore:*:*:code-interpreter/*"
      }
    ]
  }

  # Code interpreter list policy document
  code_interpreter_list_policy_doc = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BedrockAgentCodeInterpreterList"
        Effect   = "Allow"
        Action   = local.code_interpreter_list_perms
        Resource = "arn:aws:bedrock-agentcore:*:*:code-interpreter/*"
      }
    ]
  }

  # Code interpreter use policy document
  code_interpreter_use_policy_doc = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BedrockAgentCodeInterpreterUse"
        Effect   = "Allow"
        Action   = local.code_interpreter_use_perms
        Resource = "arn:aws:bedrock-agentcore:*:*:code-interpreter/*"
      }
    ]
  }
}

resource "awscc_bedrockagentcore_code_interpreter_custom" "agent_code_interpreter" {
  count              = local.create_code_interpreter ? 1 : 0
  name               = "${random_string.solution_prefix.result}_${local.sanitized_code_interpreter_name}"
  description        = var.code_interpreter_description
  execution_role_arn = var.code_interpreter_role_arn != null ? var.code_interpreter_role_arn : aws_iam_role.code_interpreter_role[0].arn

  network_configuration = {
    network_mode = var.code_interpreter_network_mode
    vpc_config = var.code_interpreter_network_mode == "VPC" ? {
      security_groups = var.code_interpreter_network_configuration.security_groups
      subnets         = var.code_interpreter_network_configuration.subnets
    } : null
  }

  tags = var.code_interpreter_tags

  # Explicit dependency to avoid race conditions with IAM role creation
  depends_on = [
    aws_iam_role.code_interpreter_role,
    aws_iam_role_policy.code_interpreter_role_policy,
    time_sleep.code_interpreter_iam_role_propagation
  ]
}

# IAM Role for Code Interpreter
resource "aws_iam_role" "code_interpreter_role" {
  count = local.create_code_interpreter && var.code_interpreter_role_arn == null ? 1 : 0
  name  = "${random_string.solution_prefix.result}-bedrock-agent-code-interpreter-role"

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
  tags                 = var.code_interpreter_tags
}

# IAM Policy for Code Interpreter
resource "aws_iam_role_policy" "code_interpreter_role_policy" {
  count = local.create_code_interpreter && var.code_interpreter_role_arn == null ? 1 : 0
  name  = "${random_string.solution_prefix.result}-bedrock-agent-code-interpreter-policy"
  role  = aws_iam_role.code_interpreter_role[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/code-interpreters/*"
        ]
      },
      {
        Sid    = "BedrockModelInvocation"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/*",
          "arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"
        ]
      }
      ],
      # Add VPC permissions if applicable
      var.code_interpreter_network_mode == "VPC" ? [{
        Sid    = "VPCAccess"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
    }] : [])
  })
}

# Add a time delay to ensure IAM role propagation
resource "time_sleep" "code_interpreter_iam_role_propagation" {
  count           = local.create_code_interpreter && var.code_interpreter_role_arn == null ? 1 : 0
  depends_on      = [aws_iam_role.code_interpreter_role, aws_iam_role_policy.code_interpreter_role_policy]
  create_duration = "20s"
}
