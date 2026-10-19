# – Bedrock Agent Core Configuration Bundle –
# A bundle is a versioned snapshot of an agent's dynamic configuration (system
# prompt, model ID, tool descriptions, ...). Components are keyed by the ARN of
# the AgentCore resource they configure; {{runtime:<name>}} and
# {{gateway:<name>}} placeholders resolve to resources created by this module.
# Nothing is attached to the runtime at deploy time: a caller selects the bundle
# per request with the W3C baggage header
#   aws.agentcore.configbundle_arn=<bundle arn>,aws.agentcore.configbundle_version=<version id>
# (InvokeAgentRuntime `baggage`), or a gateway rule / A/B test injects it, and
# the agent reads it with BedrockAgentCoreContext.get_config_bundle().

resource "awscc_bedrockagentcore_configuration_bundle" "bundle" {
  for_each = var.configuration_bundles

  bundle_name    = each.key
  description    = each.value.description
  branch_name    = each.value.branch_name
  commit_message = each.value.commit_message
  kms_key_arn    = each.value.kms_key_arn

  components = local.configuration_bundle_components[each.key]

  tags = [for k, v in merge(local.merged_tags, each.value.tags) : { key = k, value = v }]
}
