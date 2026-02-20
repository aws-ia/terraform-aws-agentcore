# – Bedrock Agent Core Browser Custom –

locals {
  create_browser = var.create_browser
  # Browser name is now validated directly in the variable definition
  # No need to sanitize here as the validation will prevent invalid names
  browser_name = var.browser_name

  # Data Plane Permissions

  # Permissions to manage a specific browser session
  browser_session_perms = [
    "bedrock-agentcore:GetBrowserSession",
    "bedrock-agentcore:ListBrowserSessions",
    "bedrock-agentcore:StartBrowserSession",
    "bedrock-agentcore:StopBrowserSession"
  ]

  # Permissions to connect to a browser live view or automation stream
  browser_stream_perms = [
    "bedrock-agentcore:UpdateBrowserStream",
    "bedrock-agentcore:ConnectBrowserAutomationStream",
    "bedrock-agentcore:ConnectBrowserLiveViewStream"
  ]

  # Control Plane Permissions

  # Grants control plane operations to manage the browser (CRUD)
  browser_admin_perms = [
    "bedrock-agentcore:CreateBrowser",
    "bedrock-agentcore:DeleteBrowser",
    "bedrock-agentcore:GetBrowser",
    "bedrock-agentcore:ListBrowsers"
  ]

  # Permissions for reading browser information
  browser_read_perms = [
    "bedrock-agentcore:GetBrowser",
    "bedrock-agentcore:GetBrowserSession"
  ]

  # Permissions for listing browser resources
  browser_list_perms = [
    "bedrock-agentcore:ListBrowsers",
    "bedrock-agentcore:ListBrowserSessions"
  ]

  # Permissions for using browser functionality
  browser_use_perms = [
    "bedrock-agentcore:StartBrowserSession",
    "bedrock-agentcore:UpdateBrowserStream",
    "bedrock-agentcore:StopBrowserSession"
  ]

  # Combined permissions for full access
  browser_full_access_perms = distinct(concat(
    local.browser_session_perms,
    local.browser_stream_perms,
    local.browser_admin_perms
  ))

  # Policy documents

  # Browser full access policy document
  browser_full_access_policy_doc = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BedrockAgentCoreBrowserFullAccess"
        Effect   = "Allow"
        Action   = local.browser_full_access_perms
        Resource = "arn:aws:bedrock-agentcore:*:*:browser/*"
      }
    ]
  }

  # Browser session policy document
  browser_session_policy_doc = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BedrockAgentCoreBrowserSession"
        Effect   = "Allow"
        Action   = local.browser_session_perms
        Resource = "arn:aws:bedrock-agentcore:*:*:browser/*"
      }
    ]
  }

  # Browser stream policy document
  browser_stream_policy_doc = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BedrockAgentCoreBrowserStream"
        Effect   = "Allow"
        Action   = local.browser_stream_perms
        Resource = "arn:aws:bedrock-agentcore:*:*:browser/*"
      }
    ]
  }

  # Browser admin policy document
  browser_admin_policy_doc = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BedrockAgentCoreBrowserAdmin"
        Effect   = "Allow"
        Action   = local.browser_admin_perms
        Resource = "arn:aws:bedrock-agentcore:*:*:browser/*"
      }
    ]
  }

  # Browser read policy document
  browser_read_policy_doc = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BedrockAgentCoreBrowserRead"
        Effect   = "Allow"
        Action   = local.browser_read_perms
        Resource = "arn:aws:bedrock-agentcore:*:*:browser/*"
      }
    ]
  }

  # Browser list policy document
  browser_list_policy_doc = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BedrockAgentCoreBrowserList"
        Effect   = "Allow"
        Action   = local.browser_list_perms
        Resource = "arn:aws:bedrock-agentcore:*:*:browser/*"
      }
    ]
  }

  # Browser use policy document
  browser_use_policy_doc = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BedrockAgentCoreBrowserUse"
        Effect   = "Allow"
        Action   = local.browser_use_perms
        Resource = "arn:aws:bedrock-agentcore:*:*:browser/*"
      }
    ]
  }
}

resource "awscc_bedrockagentcore_browser_custom" "agent_browser" {
  count              = local.create_browser ? 1 : 0
  name               = trimprefix("${local.solution_prefix}_${local.browser_name}", "-")
  description        = var.browser_description
  execution_role_arn = var.browser_role_arn != null ? var.browser_role_arn : aws_iam_role.browser_role[0].arn

  network_configuration = {
    network_mode = var.browser_network_mode
    vpc_config = var.browser_network_mode == "VPC" ? {
      security_groups = var.browser_network_configuration.security_groups
      subnets         = var.browser_network_configuration.subnets
    } : null
  }

  recording_config = var.browser_recording_enabled ? {
    enabled = true
    s3_location = {
      bucket = var.browser_recording_config.bucket
      prefix = var.browser_recording_config.prefix
    }
  } : null

  tags = var.browser_tags

  # Explicit dependency to avoid race conditions with IAM role creation
  depends_on = [
    aws_iam_role.browser_role,
    aws_iam_role_policy.browser_role_policy,
    time_sleep.browser_iam_role_propagation
  ]
}

# IAM Role for Browser
data "aws_iam_policy_document" "browser_role_assume_role" {
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

resource "aws_iam_role" "browser_role" {
  count = local.create_browser && var.browser_role_arn == null ? 1 : 0
  name  = trimprefix("${local.solution_prefix}-bedrock-agent-browser-role", "-")

  assume_role_policy = data.aws_iam_policy_document.browser_role_assume_role.json

  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.browser_tags
}

# IAM Policy for Browser
data "aws_iam_policy_document" "browser_role_policy" {

  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/browsers/*",
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

  # Add VPC permissions if applicable
  dynamic "statement" {
    for_each = var.browser_network_mode == "VPC" ? [1] : []
    content {
      sid    = "VPCAccess"
      effect = "Allow"

      actions = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
      ]

      resources = ["*"]
    }
  }

  # Add S3 permissions for recording if enabled
  dynamic "statement" {
    for_each = var.browser_recording_enabled ? [1] : []
    content {
      sid    = "S3RecordingAccess"
      effect = "Allow"

      actions = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
      ]

      resources = [
        "arn:aws:s3:::${var.browser_recording_config.bucket}",
        "arn:aws:s3:::${var.browser_recording_config.bucket}/${var.browser_recording_config.prefix}*",
      ]
    }
  }
}

resource "aws_iam_role_policy" "browser_role_policy" {
  count = local.create_browser && var.browser_role_arn == null ? 1 : 0
  name  = trimprefix("${local.solution_prefix}-bedrock-agent-browser-policy", "-")
  role  = aws_iam_role.browser_role[0].name

  policy = data.aws_iam_policy_document.browser_role_policy.json
}

# Add a time delay to ensure IAM role propagation
resource "time_sleep" "browser_iam_role_propagation" {
  count           = local.create_browser && var.browser_role_arn == null ? 1 : 0
  depends_on      = [aws_iam_role.browser_role, aws_iam_role_policy.browser_role_policy]
  create_duration = "20s"
}
