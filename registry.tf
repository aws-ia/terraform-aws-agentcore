# ═══════════════════════════════════════════════════════════════════════════
# AWS AGENT REGISTRY: REGISTRIES & REGISTRY RECORDS
# ═══════════════════════════════════════════════════════════════════════════
# AWS Agent Registry moved from the bedrock-agentcore namespace to the
# agent-registry namespace on August 6, 2026 (the bedrock-agentcore registry
# APIs and the deprecated aws_bedrockagentcore_registry resource stop working on
# October 30, 2026), so this module uses the agent-registry resources only.
# IAM for publishers (pipelines that write records) lives in iam.tf.

# ─── Registries ───

resource "awscc_agentregistry_registry" "registry" {
  for_each = var.registries

  name            = each.key
  description     = each.value.description
  authorizer_type = each.value.authorizer_type

  discovery_configuration = each.value.authorizer_type == "CUSTOM_JWT" && each.value.authorizer_configuration != null ? {
    authorizer_configuration = {
      custom_jwt_authorizer = {
        discovery_url    = each.value.authorizer_configuration.custom_jwt_authorizer.discovery_url
        allowed_audience = each.value.authorizer_configuration.custom_jwt_authorizer.allowed_audience
        allowed_clients  = each.value.authorizer_configuration.custom_jwt_authorizer.allowed_clients
        allowed_scopes   = each.value.authorizer_configuration.custom_jwt_authorizer.allowed_scopes
      }
    }
  } : null

  # APPROVE_ALL is the only rule the service supports today. An empty list means
  # every submitted record waits for a curator.
  approval_configuration = {
    auto_approval_rules = each.value.auto_approve_records ? ["APPROVE_ALL"] : []
  }

  auto_detection_enabled = each.value.auto_detection != null ? each.value.auto_detection.enabled : null
  auto_detection_scope   = each.value.auto_detection != null ? each.value.auto_detection.scope : null

  custom_metadata_schema_configuration = each.value.custom_metadata_schema != null ? {
    default_schema = each.value.custom_metadata_schema.default_schema
    record_type_schema_overrides = length(each.value.custom_metadata_schema.record_type_schema_overrides) > 0 ? [
      for override in each.value.custom_metadata_schema.record_type_schema_overrides : {
        record_type = override.record_type
        schema      = override.schema
      }
    ] : null
  } : null

  encryption_configuration = each.value.kms_key_arn != null ? {
    kms_key_arn = each.value.kms_key_arn
  } : null

  tags = [for k, v in merge(local.merged_tags, each.value.tags) : { key = k, value = v }]
}

# ─── Registry Records ───
# Records are usually written at run time by the publishing pipeline (see the
# agent-registry example for the API calls). Records declared here are managed
# by Terraform in the same way.

resource "awscc_agentregistry_registry_record" "record" {
  for_each = local.registry_records

  registry_id     = awscc_agentregistry_registry.registry[each.value.registry_name].registry_id
  name            = each.value.name
  record_type     = each.value.record_type
  description     = each.value.description
  display_name    = each.value.display_name
  record_version  = each.value.record_version
  custom_metadata = each.value.custom_metadata

  # Exactly one descriptor is populated, selected by descriptor_type.
  descriptors = {
    a2_a_agent_card = each.value.descriptor_type == "A2A_AGENT_CARD" ? {
      data                = each.value.descriptor_data
      data_schema_version = each.value.descriptor_data_schema_version
      source = each.value.descriptor_source_url != null ? {
        from_url = {
          url = each.value.descriptor_source_url
        }
      } : null
    } : null

    mcp_server = each.value.descriptor_type == "MCP_SERVER" ? {
      data                = each.value.descriptor_data
      data_schema_version = each.value.descriptor_data_schema_version
      additional_data = each.value.tools_data != null ? {
        tools = {
          data                = each.value.tools_data
          data_schema_version = each.value.tools_data_schema_version
        }
      } : null
      source = each.value.descriptor_source_url != null ? {
        from_url = {
          url = each.value.descriptor_source_url
        }
      } : null
    } : null

    agent_skills_definition = each.value.descriptor_type == "AGENT_SKILLS_DEFINITION" ? {
      data                = each.value.descriptor_data
      data_schema_version = each.value.descriptor_data_schema_version
    } : null

    custom = each.value.descriptor_type == "CUSTOM" ? {
      data = each.value.descriptor_data
    } : null
  }

  tags = [for k, v in merge(local.merged_tags, each.value.tags) : { key = k, value = v }]
}
