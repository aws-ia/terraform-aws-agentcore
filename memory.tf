# – Bedrock Agent Core Memory –

resource "awscc_bedrockagentcore_memory" "memory" {
  for_each = var.memories

  name                      = each.key
  description               = each.value.description
  event_expiry_duration     = each.value.event_expiry_duration
  encryption_key_arn        = each.value.encryption_key_arn
  memory_execution_role_arn = each.value.execution_role_arn != null ? each.value.execution_role_arn : try(aws_iam_role.memory[each.key].arn, null)

  memory_strategies = [
    for strategy in each.value.strategies : {
      semantic_memory_strategy = strategy.semantic_memory_strategy != null ? {
        name        = strategy.semantic_memory_strategy.name
        description = strategy.semantic_memory_strategy.description
        namespaces  = strategy.semantic_memory_strategy.namespaces
      } : null

      summary_memory_strategy = strategy.summary_memory_strategy != null ? {
        name        = strategy.summary_memory_strategy.name
        description = strategy.summary_memory_strategy.description
        namespaces  = strategy.summary_memory_strategy.namespaces
      } : null

      user_preference_memory_strategy = strategy.user_preference_memory_strategy != null ? {
        name        = strategy.user_preference_memory_strategy.name
        description = strategy.user_preference_memory_strategy.description
        namespaces  = strategy.user_preference_memory_strategy.namespaces
      } : null

      custom_memory_strategy = strategy.custom_memory_strategy != null ? {
        name        = strategy.custom_memory_strategy.name
        description = strategy.custom_memory_strategy.description
        namespaces  = strategy.custom_memory_strategy.namespaces

        configuration = strategy.custom_memory_strategy.configuration != null ? {
          self_managed_configuration = strategy.custom_memory_strategy.configuration.self_managed_configuration != null ? {
            historical_context_window_size = strategy.custom_memory_strategy.configuration.self_managed_configuration.historical_context_window_size
            invocation_configuration = strategy.custom_memory_strategy.configuration.self_managed_configuration.invocation_configuration != null ? {
              payload_delivery_bucket_name = strategy.custom_memory_strategy.configuration.self_managed_configuration.invocation_configuration.payload_delivery_bucket_name
              topic_arn                    = strategy.custom_memory_strategy.configuration.self_managed_configuration.invocation_configuration.topic_arn
            } : null
            trigger_conditions = strategy.custom_memory_strategy.configuration.self_managed_configuration.trigger_conditions != null ? [
              for trigger in strategy.custom_memory_strategy.configuration.self_managed_configuration.trigger_conditions : {
                message_based_trigger = trigger.message_based_trigger != null ? {
                  message_count = trigger.message_based_trigger.message_count
                } : null
                time_based_trigger = trigger.time_based_trigger != null ? {
                  idle_session_timeout = trigger.time_based_trigger.idle_session_timeout
                } : null
                token_based_trigger = trigger.token_based_trigger != null ? {
                  token_count = trigger.token_based_trigger.token_count
                } : null
              }
            ] : null
          } : null
          semantic_override = strategy.custom_memory_strategy.configuration.semantic_override != null ? {
            consolidation = strategy.custom_memory_strategy.configuration.semantic_override.consolidation != null ? {
              append_to_prompt = strategy.custom_memory_strategy.configuration.semantic_override.consolidation.append_to_prompt
              model_id         = strategy.custom_memory_strategy.configuration.semantic_override.consolidation.model_id
            } : null
            extraction = strategy.custom_memory_strategy.configuration.semantic_override.extraction != null ? {
              append_to_prompt = strategy.custom_memory_strategy.configuration.semantic_override.extraction.append_to_prompt
              model_id         = strategy.custom_memory_strategy.configuration.semantic_override.extraction.model_id
            } : null
          } : null
          summary_override = strategy.custom_memory_strategy.configuration.summary_override != null ? {
            consolidation = strategy.custom_memory_strategy.configuration.summary_override.consolidation != null ? {
              append_to_prompt = strategy.custom_memory_strategy.configuration.summary_override.consolidation.append_to_prompt
              model_id         = strategy.custom_memory_strategy.configuration.summary_override.consolidation.model_id
            } : null
          } : null
          user_preference_override = strategy.custom_memory_strategy.configuration.user_preference_override != null ? {
            consolidation = strategy.custom_memory_strategy.configuration.user_preference_override.consolidation != null ? {
              append_to_prompt = strategy.custom_memory_strategy.configuration.user_preference_override.consolidation.append_to_prompt
              model_id         = strategy.custom_memory_strategy.configuration.user_preference_override.consolidation.model_id
            } : null
            extraction = strategy.custom_memory_strategy.configuration.user_preference_override.extraction != null ? {
              append_to_prompt = strategy.custom_memory_strategy.configuration.user_preference_override.extraction.append_to_prompt
              model_id         = strategy.custom_memory_strategy.configuration.user_preference_override.extraction.model_id
            } : null
          } : null
        } : null
      } : null
    }
  ]

  tags = merge(local.merged_tags, each.value.tags)

  depends_on = [time_sleep.memory_iam_role_propagation]
}

