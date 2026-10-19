run "plan_configuration_bundles" {
  command = plan
  module {
    source = "./examples/configuration-bundles"
  }
}

run "apply_configuration_bundles" {
  command = apply
  module {
    source = "./examples/configuration-bundles"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.runtime_ids)) == 1
    error_message = "Should create exactly 1 runtime"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.configuration_bundle_ids)) == 2
    error_message = "Should create exactly 2 configuration bundles"
  }

  assert {
    condition     = contains(keys(module.terraform-aws-agentcore.configuration_bundle_ids), "support_agent_control") && contains(keys(module.terraform-aws-agentcore.configuration_bundle_ids), "support_agent_treatment")
    error_message = "Should create support_agent_control and support_agent_treatment"
  }

  assert {
    condition     = alltrue([for name, version in module.terraform-aws-agentcore.configuration_bundle_version_ids : version != null && version != ""])
    error_message = "Every configuration bundle should expose a version ID"
  }
}
