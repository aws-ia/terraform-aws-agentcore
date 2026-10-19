# – Bedrock Agent Core Workload Identity –
# AgentCore Runtime and Gateway create a workload identity for every runtime and
# gateway automatically (exposed through the runtime_workload_identity_arns and
# gateway_workload_identity_arns outputs). The identities below are the
# explicitly managed ones: agents that run outside AgentCore Runtime, or
# identities that need OAuth2 return URLs registered for 3-legged flows.

resource "aws_bedrockagentcore_workload_identity" "workload_identity" {
  for_each = var.workload_identities

  name                                = each.key
  allowed_resource_oauth2_return_urls = length(each.value.allowed_resource_oauth2_return_urls) > 0 ? each.value.allowed_resource_oauth2_return_urls : null
  tags                                = merge(local.merged_tags, each.value.tags)
}
