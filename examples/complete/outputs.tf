output "runtime_ids" {
  description = "Map of runtime names to their IDs"
  value       = module.terraform-aws-agentcore.runtime_ids
}

output "runtime_endpoints" {
  description = "Map of runtime names to their endpoint ARNs"
  value       = module.terraform-aws-agentcore.endpoint_arns
}

output "memory_ids" {
  description = "Map of memory names to their IDs"
  value       = module.terraform-aws-agentcore.memory_ids
}

output "gateway_ids" {
  description = "Map of gateway names to their IDs"
  value       = module.terraform-aws-agentcore.gateway_ids
}

output "gateway_urls" {
  description = "Map of gateway names to their URLs"
  value       = module.terraform-aws-agentcore.gateway_urls
}

output "gateway_target_ids" {
  description = "Map of gateway target names to their IDs"
  value       = module.terraform-aws-agentcore.gateway_target_ids
}

output "browser_ids" {
  description = "Map of browser names to their IDs"
  value       = module.terraform-aws-agentcore.browser_ids
}

output "code_interpreter_ids" {
  description = "Map of code interpreter names to their IDs"
  value       = module.terraform-aws-agentcore.code_interpreter_ids
}

output "ecr_repository_urls" {
  description = "Map of CONTAINER runtime names to their ECR repository URLs"
  value       = module.terraform-aws-agentcore.ecr_repository_urls
}

output "s3_bucket_names" {
  description = "Map of runtime names to their S3 bucket names"
  value       = module.terraform-aws-agentcore.s3_bucket_names
}
