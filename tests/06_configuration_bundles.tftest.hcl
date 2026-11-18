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

  assert {
    condition     = alltrue([for arn in values(module.terraform-aws-agentcore.configuration_bundle_arns) : can(regex("^arn:aws:bedrock-agentcore:[a-z0-9-]+:[0-9]{12}:configuration-bundle/", arn))])
    error_message = "Bundle ARNs should have the configuration-bundle resource type"
  }

  assert {
    condition     = alltrue([for version in values(module.terraform-aws-agentcore.configuration_bundle_version_ids) : can(regex("^[0-9a-f-]{36}$", version))])
    error_message = "Bundle version IDs should be UUIDs"
  }

  assert {
    condition     = alltrue([for name, baggage in output.configuration_bundle_baggage : strcontains(baggage, "aws.agentcore.configbundle_arn=") && strcontains(baggage, ",aws.agentcore.configbundle_version=")])
    error_message = "The baggage output should carry both bundle keys"
  }
}
