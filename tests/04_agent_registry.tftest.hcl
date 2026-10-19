run "plan_agent_registry" {
  command = plan
  module {
    source = "./examples/agent-registry"
  }
}

run "apply_agent_registry" {
  command = apply
  module {
    source = "./examples/agent-registry"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.registry_ids)) == 1
    error_message = "Should create exactly 1 registry"
  }

  assert {
    condition     = contains(keys(module.terraform-aws-agentcore.registry_ids), "team-agent-registry")
    error_message = "Should create team-agent-registry"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.registry_publisher_policy_arns)) == 1
    error_message = "Should create exactly 1 publisher IAM policy"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.registry_publisher_role_arns)) == 1
    error_message = "Should create exactly 1 publisher IAM role (trusted_services is set)"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.registry_record_ids)) == 1
    error_message = "Should create exactly 1 registry record"
  }

  assert {
    condition     = contains(keys(module.terraform-aws-agentcore.registry_record_ids), "team-agent-registry/weather-mcp-server")
    error_message = "Should create the weather-mcp-server record in team-agent-registry"
  }
}
