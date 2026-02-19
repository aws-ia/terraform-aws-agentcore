# – Bedrock Agent Core Memory –

# -----------------------------------------------------------------------------
# IAM PERMISSIONS FOR MEMORY
# -----------------------------------------------------------------------------

locals {
  # Data Plane Permissions

  # Short-Term Memory (STM) permissions
  stm_write_perms = ["bedrock-agentcore:CreateEvent"]
  stm_read_perms = [
    "bedrock-agentcore:GetEvent",
    "bedrock-agentcore:ListEvents",
    "bedrock-agentcore:ListActors",
    "bedrock-agentcore:ListSessions",
  ]
  stm_delete_perms = ["bedrock-agentcore:DeleteEvent"]

  # Long-Term Memory (LTM) permissions
  # Note: There is no "bedrock-agentcore:CreateMemoryRecord" as you cannot write directly to LTM
  # This is done asynchronously once extraction strategies have been configured
  ltm_read_perms = [
    "bedrock-agentcore:GetMemoryRecord",
    "bedrock-agentcore:RetrieveMemoryRecords", # Read via semantic query
    "bedrock-agentcore:ListMemoryRecords",
    "bedrock-agentcore:ListActors",
    "bedrock-agentcore:ListSessions",
  ]
  ltm_delete_perms = ["bedrock-agentcore:DeleteMemoryRecord"]

  # Combined permissions for both STM and LTM
  memory_read_perms   = distinct(concat(local.stm_read_perms, local.ltm_read_perms))
  memory_delete_perms = distinct(concat(local.stm_delete_perms, local.ltm_delete_perms))

  # Control Plane Permissions
  memory_admin_perms = [
    "bedrock-agentcore:CreateMemory",
    "bedrock-agentcore:GetMemory",
    "bedrock-agentcore:DeleteMemory",
    "bedrock-agentcore:UpdateMemory",
  ]

  # Full access permissions (combines all permissions)
  memory_full_access_perms = distinct(concat(
    local.stm_write_perms,
    local.memory_read_perms,
    local.memory_delete_perms,
    local.memory_admin_perms
  ))
}

locals {
  create_memory = var.create_memory
  # Sanitize memory name to ensure it follows the regex pattern ^[a-zA-Z][a-zA-Z0-9_]{0,47}$
  sanitized_memory_name = replace(var.memory_name, "-", "_")

  # Determine if KMS is being used for memory encryption
  kms_provided = var.memory_encryption_key_arn != null

  # Determine if we need to create a KMS policy
  create_kms_policy = local.create_memory && local.kms_provided
}

# Determine if we need to create an IAM role for the memory
locals {
  # Check if any strategies are custom strategies that need model access
  # Custom strategies require a role for Bedrock model access
  has_custom_strategies = length(var.memory_strategies) > 0 && contains(
    flatten([
      for strategy in var.memory_strategies :
      strategy.custom_memory_strategy != null ? ["has_custom"] : []
    ]),
    "has_custom"
  )

  # Check if any strategies are self-managed strategies that need S3/SNS access
  has_self_managed_strategies = length(var.memory_strategies) > 0 && contains(
    flatten([
      for strategy in var.memory_strategies :
      strategy.custom_memory_strategy != null &&
      strategy.custom_memory_strategy.configuration != null &&
      strategy.custom_memory_strategy.configuration.self_managed_configuration != null ? ["has_self_managed"] : []
    ]),
    "has_self_managed"
  )

  # Only create a role if we have custom strategies that need model access
  create_memory_role = local.create_memory && var.memory_execution_role_arn == null && (local.has_custom_strategies || local.create_kms_policy)
}

# IAM Role for Agent Memory 
data "aws_iam_policy_document" "memory_role_assume_role" {
  statement {
    sid     = "AssumeRolePolicy"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["bedrock-agentcore.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "memory_role" {
  count = local.create_memory_role ? 1 : 0
  name  = trimprefix("${local.solution_prefix}-bedrock-agent-memory-role", "-")

  assume_role_policy = data.aws_iam_policy_document.memory_role_assume_role.json

  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.memory_tags
}

# Get the AWS managed policy for Bedrock AgentCore Memory model inference
data "aws_iam_policy" "bedrock_memory_inference_policy" {
  name = "AmazonBedrockAgentCoreMemoryBedrockModelInferenceExecutionRolePolicy"
}

# Attach the managed policy to the memory role
resource "aws_iam_role_policy_attachment" "memory_execution_policy" {
  count      = local.create_memory_role && local.has_custom_strategies ? 1 : 0
  role       = aws_iam_role.memory_role[0].name
  policy_arn = data.aws_iam_policy.bedrock_memory_inference_policy.arn
}

# Extract all payload bucket names and SNS topics from memory strategies
locals {
  # Get all unique bucket names from self-managed strategies
  s3_bucket_names = distinct(compact([
    for strategy in var.memory_strategies :
    try(strategy.custom_memory_strategy.configuration.self_managed_configuration.invocation_configuration.payload_delivery_bucket_name, null)
    if strategy.custom_memory_strategy != null &&
    strategy.custom_memory_strategy.configuration != null &&
    strategy.custom_memory_strategy.configuration.self_managed_configuration != null &&
    strategy.custom_memory_strategy.configuration.self_managed_configuration.invocation_configuration != null
  ]))

  # Get all unique SNS topic ARNs from self-managed strategies
  sns_topic_arns = distinct(compact([
    for strategy in var.memory_strategies :
    try(strategy.custom_memory_strategy.configuration.self_managed_configuration.invocation_configuration.topic_arn, null)
    if strategy.custom_memory_strategy != null &&
    strategy.custom_memory_strategy.configuration != null &&
    strategy.custom_memory_strategy.configuration.self_managed_configuration != null &&
    strategy.custom_memory_strategy.configuration.self_managed_configuration.invocation_configuration != null
  ]))
}

# Create policy for self-managed memory strategies
data "aws_iam_policy_document" "memory_self_managed_policy" {

  # S3 bucket permissions
  statement {
    sid    = "S3PayloadDelivery"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:PutObject",
    ]

    resources = flatten([
      for bucket in local.s3_bucket_names : [
        "arn:aws:s3:::${bucket}",
        "arn:aws:s3:::${bucket}/*"
      ]
    ])
  }

  # SNS topic permissions
  statement {
    sid    = "SNSNotifications"
    effect = "Allow"

    actions = [
      "sns:GetTopicAttributes",
      "sns:Publish",
    ]

    resources = local.sns_topic_arns
  }
}

resource "aws_iam_policy" "memory_self_managed_policy" {
  # Only create if we have a memory role AND self-managed strategies are present
  count       = local.create_memory_role && local.has_self_managed_strategies ? 1 : 0
  name        = trimprefix("${local.solution_prefix}-bedrock-agent-memory-self-managed-policy", "-")
  description = "Policy for Bedrock AgentCore self-managed memory strategies"

  policy = data.aws_iam_policy_document.memory_self_managed_policy.json
}

# Attach the self-managed policy to the memory role
resource "aws_iam_role_policy_attachment" "memory_self_managed_policy" {
  # Only attach if we have a memory role AND self-managed strategies are present
  count      = local.create_memory_role && local.has_self_managed_strategies ? 1 : 0
  role       = aws_iam_role.memory_role[0].name
  policy_arn = aws_iam_policy.memory_self_managed_policy[0].arn
}

# Create policy for KMS access when memory_encryption_key_arn is provided
data "aws_iam_policy_document" "memory_kms_policy" {
  count = local.create_kms_policy ? 1 : 0

  statement {
    sid    = "AllowAgentCoreMemoryKMS"
    effect = "Allow"

    actions = [
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncrypt*",
    ]

    resources = [var.memory_encryption_key_arn]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["bedrock-agentcore.*.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "memory_kms_policy" {
  count       = local.create_kms_policy ? 1 : 0
  name        = trimprefix("${local.solution_prefix}-bedrock-agent-memory-kms-policy", "-")
  description = "Policy for Bedrock AgentCore memory KMS access"

  policy = data.aws_iam_policy_document.memory_kms_policy[0].json
}

# Attach the KMS policy to the memory role when KMS is provided and a role exists
resource "aws_iam_role_policy_attachment" "memory_kms_policy" {
  count      = local.create_kms_policy ? 1 : 0
  role       = aws_iam_role.memory_role[0].name
  policy_arn = aws_iam_policy.memory_kms_policy[0].arn
}


# Add a time delay to ensure IAM role propagation
resource "time_sleep" "memory_iam_role_propagation" {
  count = local.create_memory_role ? 1 : 0
  depends_on = [
    aws_iam_role.memory_role,
    aws_iam_role_policy_attachment.memory_execution_policy,
    aws_iam_role_policy_attachment.memory_self_managed_policy,
    aws_iam_role_policy_attachment.memory_kms_policy
  ]
  create_duration = "20s"
}

# Policy documents for granting to other resources - for external use
locals {
  # STM Write permissions policy document
  memory_stm_write_policy_doc = {
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = local.stm_write_perms
      Resource = "*"
    }]
  }

  # Memory Read permissions policy document (both STM and LTM)
  memory_read_policy_doc = {
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = local.memory_read_perms
      Resource = "*"
    }]
  }

  # STM Read permissions policy document
  memory_stm_read_policy_doc = {
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = local.stm_read_perms
      Resource = "*"
    }]
  }

  # LTM Read permissions policy document
  memory_ltm_read_policy_doc = {
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = local.ltm_read_perms
      Resource = "*"
    }]
  }

  # Memory Delete permissions policy document (both STM and LTM)
  memory_delete_policy_doc = {
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = local.memory_delete_perms
      Resource = "*"
    }]
  }

  # STM Delete permissions policy document
  memory_stm_delete_policy_doc = {
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = local.stm_delete_perms
      Resource = "*"
    }]
  }

  # LTM Delete permissions policy document
  memory_ltm_delete_policy_doc = {
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = local.ltm_delete_perms
      Resource = "*"
    }]
  }

  # Memory Admin permissions policy document
  memory_admin_policy_doc = {
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = local.memory_admin_perms
      Resource = "*"
    }]
  }

  # Memory Full Access permissions policy document
  memory_full_access_policy_doc = {
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = local.memory_full_access_perms
      Resource = "*"
    }]
  }
}

resource "awscc_bedrockagentcore_memory" "agent_memory" {
  count                     = local.create_memory ? 1 : 0
  name                      = trimprefix("${local.solution_prefix}_${local.sanitized_memory_name}", "_")
  description               = var.memory_description
  event_expiry_duration     = var.memory_event_expiry_duration
  encryption_key_arn        = var.memory_encryption_key_arn
  memory_execution_role_arn = var.memory_execution_role_arn != null ? var.memory_execution_role_arn : (local.create_memory_role ? try(aws_iam_role.memory_role[0].arn, null) : null)

  # Explicit dependency to avoid race conditions with IAM role creation
  depends_on = [
    time_sleep.memory_iam_role_propagation
  ]

  # Direct assignment of memory strategies
  memory_strategies = [
    for strategy in var.memory_strategies : {
      # Semantic memory strategy
      semantic_memory_strategy = strategy.semantic_memory_strategy != null ? {
        name        = strategy.semantic_memory_strategy.name
        description = strategy.semantic_memory_strategy.description
        namespaces  = strategy.semantic_memory_strategy.namespaces
      } : null

      # Summary memory strategy
      summary_memory_strategy = strategy.summary_memory_strategy != null ? {
        name        = strategy.summary_memory_strategy.name
        description = strategy.summary_memory_strategy.description
        namespaces  = strategy.summary_memory_strategy.namespaces
      } : null

      # User preference memory strategy
      user_preference_memory_strategy = strategy.user_preference_memory_strategy != null ? {
        name        = strategy.user_preference_memory_strategy.name
        description = strategy.user_preference_memory_strategy.description
        namespaces  = strategy.user_preference_memory_strategy.namespaces
      } : null

      # Custom memory strategy
      custom_memory_strategy = strategy.custom_memory_strategy != null ? {
        name        = strategy.custom_memory_strategy.name
        description = strategy.custom_memory_strategy.description
        namespaces  = strategy.custom_memory_strategy.namespaces

        # Custom strategy configuration
        configuration = strategy.custom_memory_strategy.configuration != null ? {
          # Self-managed configuration
          self_managed_configuration = strategy.custom_memory_strategy.configuration.self_managed_configuration != null ? {
            historical_context_window_size = strategy.custom_memory_strategy.configuration.self_managed_configuration.historical_context_window_size

            # Invocation configuration
            invocation_configuration = strategy.custom_memory_strategy.configuration.self_managed_configuration.invocation_configuration != null ? {
              payload_delivery_bucket_name = strategy.custom_memory_strategy.configuration.self_managed_configuration.invocation_configuration.payload_delivery_bucket_name
              topic_arn                    = strategy.custom_memory_strategy.configuration.self_managed_configuration.invocation_configuration.topic_arn
            } : null

            # Trigger conditions
            trigger_conditions = strategy.custom_memory_strategy.configuration.self_managed_configuration.trigger_conditions != null ? [
              for trigger in strategy.custom_memory_strategy.configuration.self_managed_configuration.trigger_conditions : {
                # Message-based trigger
                message_based_trigger = trigger.message_based_trigger != null ? {
                  message_count = trigger.message_based_trigger.message_count
                } : null

                # Time-based trigger
                time_based_trigger = trigger.time_based_trigger != null ? {
                  idle_session_timeout = trigger.time_based_trigger.idle_session_timeout
                } : null

                # Token-based trigger
                token_based_trigger = trigger.token_based_trigger != null ? {
                  token_count = trigger.token_based_trigger.token_count
                } : null
              }
            ] : null
          } : null

          # Semantic override
          semantic_override = strategy.custom_memory_strategy.configuration.semantic_override != null ? {
            # Consolidation
            consolidation = strategy.custom_memory_strategy.configuration.semantic_override.consolidation != null ? {
              append_to_prompt = strategy.custom_memory_strategy.configuration.semantic_override.consolidation.append_to_prompt
              model_id         = strategy.custom_memory_strategy.configuration.semantic_override.consolidation.model_id
            } : null

            # Extraction
            extraction = strategy.custom_memory_strategy.configuration.semantic_override.extraction != null ? {
              append_to_prompt = strategy.custom_memory_strategy.configuration.semantic_override.extraction.append_to_prompt
              model_id         = strategy.custom_memory_strategy.configuration.semantic_override.extraction.model_id
            } : null
          } : null

          # Summary override
          summary_override = strategy.custom_memory_strategy.configuration.summary_override != null ? {
            # Consolidation
            consolidation = strategy.custom_memory_strategy.configuration.summary_override.consolidation != null ? {
              append_to_prompt = strategy.custom_memory_strategy.configuration.summary_override.consolidation.append_to_prompt
              model_id         = strategy.custom_memory_strategy.configuration.summary_override.consolidation.model_id
            } : null
          } : null

          # User preference override
          user_preference_override = strategy.custom_memory_strategy.configuration.user_preference_override != null ? {
            # Consolidation
            consolidation = strategy.custom_memory_strategy.configuration.user_preference_override.consolidation != null ? {
              append_to_prompt = strategy.custom_memory_strategy.configuration.user_preference_override.consolidation.append_to_prompt
              model_id         = strategy.custom_memory_strategy.configuration.user_preference_override.consolidation.model_id
            } : null

            # Extraction
            extraction = strategy.custom_memory_strategy.configuration.user_preference_override.extraction != null ? {
              append_to_prompt = strategy.custom_memory_strategy.configuration.user_preference_override.extraction.append_to_prompt
              model_id         = strategy.custom_memory_strategy.configuration.user_preference_override.extraction.model_id
            } : null
          } : null
        } : null
      } : null
    }
  ]

  tags = var.memory_tags
}
