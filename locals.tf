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
