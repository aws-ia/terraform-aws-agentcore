output "registry_ids" {
  description = "Map of registry names to their IDs"
  value       = module.terraform-aws-agentcore.registry_ids
}

output "registry_arns" {
  description = "Map of registry names to their ARNs"
  value       = module.terraform-aws-agentcore.registry_arns
}

output "registry_publisher_policy_arns" {
  description = "Map of registry names to the publisher IAM policy ARN (attach it to a pipeline role)"
  value       = module.terraform-aws-agentcore.registry_publisher_policy_arns
}

output "registry_publisher_role_arns" {
  description = "Map of registry names to the publisher IAM role ARN"
  value       = module.terraform-aws-agentcore.registry_publisher_role_arns
}

output "registry_record_ids" {
  description = "Map of '<registry name>/<record name>' to registry record IDs"
  value       = module.terraform-aws-agentcore.registry_record_ids
}
