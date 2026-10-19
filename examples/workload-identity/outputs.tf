output "runtime_ids" {
  description = "Map of runtime names to their IDs"
  value       = module.terraform-aws-agentcore.runtime_ids
}

output "runtime_workload_identity_arns" {
  description = "Map of runtime names to the ARN of the workload identity AgentCore created for the runtime"
  value       = module.terraform-aws-agentcore.runtime_workload_identity_arns
}

output "workload_identity_arns" {
  description = "Map of workload identity names to their ARNs"
  value       = module.terraform-aws-agentcore.workload_identity_arns
}

output "runtime_role_arns" {
  description = "Map of runtime names to their IAM role ARNs"
  value       = module.terraform-aws-agentcore.runtime_role_arns
}
