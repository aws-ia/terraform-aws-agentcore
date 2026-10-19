# ═══════════════════════════════════════════════════════════════════════════
# BEDROCK AGENTCORE POLICY ENGINES & POLICIES
# ═══════════════════════════════════════════════════════════════════════════
# A policy engine is attached to a gateway through the gateway's
# policy_engine_configuration (see gateway.tf). Policies are evaluated against
# the tools of the gateways attached to the engine, so they are created after
# the gateways and gateway targets.

# ─── Policy Engines ───

resource "awscc_bedrockagentcore_policy_engine" "policy_engine" {
  for_each = var.policy_engines

  name               = each.key
  description        = each.value.description
  encryption_key_arn = each.value.encryption_key_arn

  tags = [for k, v in merge(local.merged_tags, each.value.tags) : { key = k, value = v }]
}

# ─── Policies (Cedar or Dogwood) ───

resource "awscc_bedrockagentcore_policy" "policy" {
  for_each = local.policies

  name             = each.value.name
  description      = each.value.description
  policy_engine_id = awscc_bedrockagentcore_policy_engine.policy_engine[each.value.engine_name].policy_engine_id
  enforcement_mode = each.value.enforcement_mode
  validation_mode  = each.value.validation_mode

  # CEDAR statements go in definition.cedar, DOGWOOD statements (temporal rules,
  # guardrail conditions) go in definition.policy.
  definition = {
    cedar = each.value.language == "CEDAR" ? {
      statement = each.value.statement
    } : null
    policy = each.value.language == "DOGWOOD" ? {
      statement = each.value.statement
    } : null
  }

  # Policy validation needs the gateway (and its tools) that the statement
  # references, and the gateway must already be attached to the engine.
  depends_on = [
    awscc_bedrockagentcore_gateway.gateway,
    aws_bedrockagentcore_gateway_target.gateway_target
  ]
}
