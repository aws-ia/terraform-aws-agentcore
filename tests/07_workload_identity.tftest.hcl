run "plan_workload_identity" {
  command = plan
  module {
    source = "./examples/workload-identity"
  }
}

run "apply_workload_identity" {
  command = apply
  module {
    source = "./examples/workload-identity"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.runtime_ids)) == 1
    error_message = "Should create exactly 1 runtime"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.workload_identity_arns)) == 1
    error_message = "Should create exactly 1 workload identity"
  }

  assert {
    condition     = contains(keys(module.terraform-aws-agentcore.workload_identity_arns), "external-support-agent")
    error_message = "Should create external-support-agent"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.runtime_workload_identity_arns)) == 1
    error_message = "Should expose the workload identity AgentCore created for the runtime"
  }
}
