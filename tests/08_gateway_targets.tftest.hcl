run "plan_gateway_targets" {
  command = plan
  module {
    source = "./examples/gateway-targets"
  }
}

run "apply_gateway_targets" {
  command = apply
  module {
    source = "./examples/gateway-targets"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.runtime_ids)) == 1
    error_message = "Should create exactly 1 runtime"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.gateway_ids)) == 2
    error_message = "Should create exactly 2 gateways (MCP and NONE protocol types)"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.gateway_target_ids)) == 3
    error_message = "Should create exactly 3 gateway targets (MCP server, runtime, passthrough)"
  }

  assert {
    condition     = contains(keys(module.terraform-aws-agentcore.gateway_target_ids), "support-agent") && contains(keys(module.terraform-aws-agentcore.gateway_target_ids), "partner-agent")
    error_message = "Should create the support-agent runtime target and the partner-agent passthrough target"
  }
}
