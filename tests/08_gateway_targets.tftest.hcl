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

  assert {
    condition     = module.terraform-aws-agentcore.gateway_target_names["support-agent"] == "targets-example-support-agent"
    error_message = "HTTP targets are addressed by their prefixed name"
  }

  assert {
    condition     = alltrue([for url in values(module.terraform-aws-agentcore.gateway_urls) : startswith(url, "https://")])
    error_message = "Both gateways should expose an HTTPS URL"
  }

  assert {
    condition     = can(regex("/\\.well-known/openid-configuration$", output.discovery_url))
    error_message = "The example's discovery URL should be an OpenID Connect discovery document"
  }
}
