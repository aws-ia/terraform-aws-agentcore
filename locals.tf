# =============================================================================
# LOCALS
# =============================================================================

locals {
  module_version = trimspace(file("${path.module}/VERSION"))
  merged_tags = merge(
    var.tags,
    { ModuleVersion = local.module_version }
  )
}

# =============================================================================
# AGENT REGISTRY
# =============================================================================

locals {
  registry_descriptor_defaults = {
    AGENT  = "A2A_AGENT_CARD"
    MCP    = "MCP_SERVER"
    SKILL  = "AGENT_SKILLS_DEFINITION"
    CUSTOM = "CUSTOM"
  }

  # Flatten registries -> records into one map keyed "<registry>/<record>"
  registry_records = merge([
    for registry_name, registry in var.registries : {
      for record_name, record in registry.records : "${registry_name}/${record_name}" => merge(record, {
        registry_name   = registry_name
        name            = record_name
        descriptor_type = record.descriptor_type != null ? record.descriptor_type : local.registry_descriptor_defaults[record.record_type]
      })
    }
  ]...)

  # Registries that get a publisher IAM policy / role
  registry_publisher_policies = {
    for name, config in var.registries : name => config
    if config.publisher.create_policy
  }
  registry_publisher_roles = {
    for name, config in var.registries : name => config
    if config.publisher.create_policy && (length(config.publisher.trusted_principal_arns) + length(config.publisher.trusted_services)) > 0
  }
}

# =============================================================================
# PLACEHOLDER RESOLUTION
# =============================================================================
# Policy statements and configuration bundle component keys often need the ARN
# or name of a resource created in the same module call, which is only known
# after apply. These placeholders are replaced before the value is sent to AWS
# (the same convention the AgentCore CLI uses):
#   {{gateway:<name>}} -> gateway ARN
#   {{target:<name>}}  -> gateway target name (gateway tools are named <target name>___<tool>)
#   {{runtime:<name>}} -> runtime ARN

locals {
  placeholder_values = merge(
    { for k, v in awscc_bedrockagentcore_gateway.gateway : "gateway:${k}" => v.gateway_arn },
    { for k, v in aws_bedrockagentcore_gateway_target.gateway_target : "target:${k}" => v.name },
    { for k, v in awscc_bedrockagentcore_runtime.runtime_code : "runtime:${k}" => v.agent_runtime_arn },
    { for k, v in awscc_bedrockagentcore_runtime.runtime_container : "runtime:${k}" => v.agent_runtime_arn }
  )
}

# =============================================================================
# POLICY ENGINES & POLICIES
# =============================================================================

locals {
  # Policy engine ARN per gateway that attaches one (module-managed by name or given by ARN)
  gateway_policy_engine_arns = {
    for name, config in var.gateways :
    name => coalesce(
      config.policy_engine_configuration.policy_engine_arn,
      try(awscc_bedrockagentcore_policy_engine.policy_engine[config.policy_engine_configuration.policy_engine_name].policy_engine_arn, null)
    )
    if config.policy_engine_configuration != null
  }

  # Flatten policy engines -> policies into one map keyed "<engine>/<policy>",
  # resolving placeholders in the statement text.
  policies = merge([
    for engine_name, engine in var.policy_engines : {
      for policy in engine.policies : "${engine_name}/${policy.name}" => {
        engine_name      = engine_name
        name             = policy.name
        description      = policy.description
        language         = policy.language
        enforcement_mode = policy.enforcement_mode
        validation_mode  = policy.validation_mode
        statement = join("", [
          for i, part in split("{{", policy.statement) : (
            i == 0 ? part : [
              for key in [try(regex("^((?:gateway|target|runtime):[A-Za-z0-9_.-]+)}}", part)[0], "")] :
              lookup(local.placeholder_values, key, null) != null
              ? "${lookup(local.placeholder_values, key, null)}${substr(part, length(key) + 2, -1)}"
              : "{{${part}"
            ][0]
          )
        ])
      }
    }
  ]...)
}

# =============================================================================
# CONFIGURATION BUNDLES
# =============================================================================

locals {
  # Component identifier => { configuration = <json> }, resolving placeholders in the identifier.
  configuration_bundle_components = {
    for bundle_name, bundle in var.configuration_bundles : bundle_name => {
      for component_id, configuration in bundle.components :
      join("", [
        for i, part in split("{{", component_id) : (
          i == 0 ? part : [
            for key in [try(regex("^((?:gateway|target|runtime):[A-Za-z0-9_.-]+)}}", part)[0], "")] :
            lookup(local.placeholder_values, key, null) != null
            ? "${lookup(local.placeholder_values, key, null)}${substr(part, length(key) + 2, -1)}"
            : "{{${part}"
          ][0]
        )
      ]) => { configuration = jsonencode(configuration) }
    }
  }
}

# =============================================================================
# RUNTIME INBOUND AUTHORIZATION
# =============================================================================

locals {
  # awscc shape of the custom JWT authorizer per runtime (null when the runtime uses IAM)
  runtime_authorizer_configurations = {
    for name, config in var.runtimes : name => (
      config.authorizer_configuration != null ? {
        custom_jwt_authorizer = {
          discovery_url    = config.authorizer_configuration.custom_jwt_authorizer.discovery_url
          allowed_audience = config.authorizer_configuration.custom_jwt_authorizer.allowed_audience
          allowed_clients  = config.authorizer_configuration.custom_jwt_authorizer.allowed_clients
          allowed_scopes   = config.authorizer_configuration.custom_jwt_authorizer.allowed_scopes
          custom_claims = length(config.authorizer_configuration.custom_jwt_authorizer.custom_claims) > 0 ? [
            for claim in config.authorizer_configuration.custom_jwt_authorizer.custom_claims : {
              inbound_token_claim_name       = claim.inbound_token_claim_name
              inbound_token_claim_value_type = claim.inbound_token_claim_value_type
              authorizing_claim_match_value = {
                claim_match_operator = claim.claim_match_operator
                claim_match_value = {
                  match_value_string      = claim.match_value_string
                  match_value_string_list = claim.match_value_string_list
                }
              }
            }
          ] : null
          allowed_workload_configuration = config.authorizer_configuration.custom_jwt_authorizer.allowed_workload_configuration != null ? {
            workload_identities = length(config.authorizer_configuration.custom_jwt_authorizer.allowed_workload_configuration.workload_identities) > 0 ? config.authorizer_configuration.custom_jwt_authorizer.allowed_workload_configuration.workload_identities : null
            hosting_environments = length(config.authorizer_configuration.custom_jwt_authorizer.allowed_workload_configuration.hosting_environment_arns) > 0 ? [
              for arn in config.authorizer_configuration.custom_jwt_authorizer.allowed_workload_configuration.hosting_environment_arns : { arn = arn }
            ] : null
          } : null
        }
      } : null
    )
  }
}

# =============================================================================
# GATEWAY INBOUND AUTHORIZATION
# =============================================================================

locals {
  # awscc shape of the custom JWT authorizer per gateway (null when the gateway uses IAM)
  gateway_authorizer_configurations = {
    for name, config in var.gateways : name => (
      config.authorizer_type == "CUSTOM_JWT" && config.authorizer_configuration != null ? {
        custom_jwt_authorizer = {
          discovery_url            = config.authorizer_configuration.custom_jwt_authorizer.discovery_url
          allowed_audience         = config.authorizer_configuration.custom_jwt_authorizer.allowed_audience
          allowed_clients          = config.authorizer_configuration.custom_jwt_authorizer.allowed_clients
          allowed_scopes           = config.authorizer_configuration.custom_jwt_authorizer.allowed_scopes
          advertised_scope_mapping = config.authorizer_configuration.custom_jwt_authorizer.advertised_scope_mapping
          custom_claims = length(config.authorizer_configuration.custom_jwt_authorizer.custom_claims) > 0 ? [
            for claim in config.authorizer_configuration.custom_jwt_authorizer.custom_claims : {
              inbound_token_claim_name       = claim.inbound_token_claim_name
              inbound_token_claim_value_type = claim.inbound_token_claim_value_type
              authorizing_claim_match_value = {
                claim_match_operator = claim.claim_match_operator
                claim_match_value = {
                  match_value_string      = claim.match_value_string
                  match_value_string_list = claim.match_value_string_list
                }
              }
            }
          ] : null
        }
      } : null
    )
  }
}

# =============================================================================
# GATEWAY TARGETS
# =============================================================================

locals {
  # Runtime ARNs by name (CODE and CONTAINER). Kept separate from placeholder_values,
  # which also contains the gateway targets themselves.
  runtime_arns = merge(
    { for k, v in awscc_bedrockagentcore_runtime.runtime_code : k => v.agent_runtime_arn },
    { for k, v in awscc_bedrockagentcore_runtime.runtime_container : k => v.agent_runtime_arn }
  )

  # Runtime ARN per AGENTCORE_RUNTIME target (module-managed by name, or given by ARN)
  gateway_target_runtime_arns = {
    for name, config in var.gateway_targets :
    name => coalesce(
      config.agentcore_runtime_config.runtime_arn,
      try(local.runtime_arns[config.agentcore_runtime_config.runtime_name], null)
    )
    if config.type == "AGENTCORE_RUNTIME" && config.agentcore_runtime_config != null
  }
}
