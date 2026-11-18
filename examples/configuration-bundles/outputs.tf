output "runtime_ids" {
  description = "Map of runtime names to their IDs"
  value       = module.terraform-aws-agentcore.runtime_ids
}

output "runtime_arns" {
  description = "Map of runtime names to their ARNs (the bundle component key)"
  value       = module.terraform-aws-agentcore.runtime_arns
}

output "configuration_bundle_arns" {
  description = "Map of configuration bundle names to their ARNs"
  value       = module.terraform-aws-agentcore.configuration_bundle_arns
}

output "configuration_bundle_version_ids" {
  description = "Map of configuration bundle names to their current version IDs"
  value       = module.terraform-aws-agentcore.configuration_bundle_version_ids
}

output "configuration_bundle_baggage" {
  description = "Per-bundle W3C baggage value that selects the bundle's current version for a request"
  value = {
    for name, arn in module.terraform-aws-agentcore.configuration_bundle_arns :
    name => "aws.agentcore.configbundle_arn=${arn},aws.agentcore.configbundle_version=${module.terraform-aws-agentcore.configuration_bundle_version_ids[name]}"
  }
}
