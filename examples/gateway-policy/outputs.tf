output "gateway_ids" {
  description = "Map of gateway names to their IDs"
  value       = module.terraform-aws-agentcore.gateway_ids
}

output "gateway_urls" {
  description = "Map of gateway names to their URLs"
  value       = module.terraform-aws-agentcore.gateway_urls
}

output "gateway_target_names" {
  description = "Map of gateway target names to their resource names (tool names are <target name>___<tool>)"
  value       = module.terraform-aws-agentcore.gateway_target_names
}

output "policy_engine_ids" {
  description = "Map of policy engine names to their IDs"
  value       = module.terraform-aws-agentcore.policy_engine_ids
}

output "policy_engine_arns" {
  description = "Map of policy engine names to their ARNs"
  value       = module.terraform-aws-agentcore.policy_engine_arns
}

output "policy_ids" {
  description = "Map of '<policy engine name>/<policy name>' to policy IDs"
  value       = module.terraform-aws-agentcore.policy_ids
}
