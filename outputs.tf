# =============================================================================
# RUNTIME OUTPUTS
# =============================================================================

output "runtime_ids" {
  description = "Map of runtime names to their IDs"
  value = merge(
    { for k, v in awscc_bedrockagentcore_runtime.runtime_code : k => v.agent_runtime_id },
    { for k, v in awscc_bedrockagentcore_runtime.runtime_container : k => v.agent_runtime_id }
  )
}

output "runtime_arns" {
  description = "Map of runtime names to their ARNs"
  value = merge(
    { for k, v in awscc_bedrockagentcore_runtime.runtime_code : k => v.agent_runtime_arn },
    { for k, v in awscc_bedrockagentcore_runtime.runtime_container : k => v.agent_runtime_arn }
  )
}

output "runtime_versions" {
  description = "Map of runtime names to their versions"
  value = merge(
    { for k, v in awscc_bedrockagentcore_runtime.runtime_code : k => v.agent_runtime_version },
    { for k, v in awscc_bedrockagentcore_runtime.runtime_container : k => v.agent_runtime_version }
  )
}

output "endpoint_ids" {
  description = "Map of runtime names to their endpoint IDs"
  value       = { for k, v in awscc_bedrockagentcore_runtime_endpoint.runtime : k => v.id }
}

output "endpoint_arns" {
  description = "Map of runtime names to their endpoint ARNs"
  value       = { for k, v in awscc_bedrockagentcore_runtime_endpoint.runtime : k => v.agent_runtime_endpoint_arn }
}

output "runtime_role_arns" {
  description = "Map of runtime names to their IAM role ARNs"
  value       = { for k, v in aws_iam_role.runtime : k => v.arn }
}

output "runtime_workload_identity_details" {
  description = "Map of runtime names to their workload identity details (if applicable)"
  value = merge(
    { for k, v in awscc_bedrockagentcore_runtime.runtime_code : k => v.workload_identity_details },
    { for k, v in awscc_bedrockagentcore_runtime.runtime_container : k => v.workload_identity_details },
  )
}

output "ecr_repository_urls" {
  description = "Map of CONTAINER runtime names to their ECR repository URLs"
  value       = { for k, v in aws_ecr_repository.runtime : k => v.repository_url }
}

output "s3_bucket_names" {
  description = "Map of runtime names to their S3 bucket names"
  value       = { for k, v in aws_s3_bucket.runtime : k => v.id }
}

output "codebuild_project_names" {
  description = "Map of CONTAINER runtime names to their CodeBuild project names"
  value = merge(
    { for k, v in aws_codebuild_project.runtime_container : k => v.name },
    { for k, v in aws_codebuild_project.runtime_code : k => v.name }
  )
}

# =============================================================================
# CODE INTERPRETER OUTPUTS
# =============================================================================

output "code_interpreter_ids" {
  description = "Map of code interpreter names to their IDs"
  value       = { for k, v in awscc_bedrockagentcore_code_interpreter_custom.code_interpreter : k => v.code_interpreter_id }
}

output "code_interpreter_arns" {
  description = "Map of code interpreter names to their ARNs"
  value       = { for k, v in awscc_bedrockagentcore_code_interpreter_custom.code_interpreter : k => v.code_interpreter_arn }
}

output "code_interpreter_statuses" {
  description = "Map of code interpreter names to their statuses"
  value       = { for k, v in awscc_bedrockagentcore_code_interpreter_custom.code_interpreter : k => v.status }
}

output "code_interpreter_role_arns" {
  description = "Map of code interpreter names to their IAM role ARNs"
  value       = { for k, v in aws_iam_role.code_interpreter : k => v.arn }
}

# =============================================================================
# BROWSER OUTPUTS
# =============================================================================

output "browser_ids" {
  description = "Map of browser names to their IDs"
  value       = { for k, v in awscc_bedrockagentcore_browser_custom.browser : k => v.browser_id }
}

output "browser_arns" {
  description = "Map of browser names to their ARNs"
  value       = { for k, v in awscc_bedrockagentcore_browser_custom.browser : k => v.browser_arn }
}

output "browser_statuses" {
  description = "Map of browser names to their statuses"
  value       = { for k, v in awscc_bedrockagentcore_browser_custom.browser : k => v.status }
}

output "browser_role_arns" {
  description = "Map of browser names to their IAM role ARNs"
  value       = { for k, v in aws_iam_role.browser : k => v.arn }
}

# =============================================================================
# GATEWAY OUTPUTS
# =============================================================================

output "gateway_ids" {
  description = "Map of gateway names to their IDs"
  value       = { for k, v in awscc_bedrockagentcore_gateway.gateway : k => v.gateway_identifier }
}

output "gateway_arns" {
  description = "Map of gateway names to their ARNs"
  value       = { for k, v in awscc_bedrockagentcore_gateway.gateway : k => v.gateway_arn }
}

output "gateway_urls" {
  description = "Map of gateway names to their URLs"
  value       = { for k, v in awscc_bedrockagentcore_gateway.gateway : k => v.gateway_url }
}

output "gateway_statuses" {
  description = "Map of gateway names to their statuses"
  value       = { for k, v in awscc_bedrockagentcore_gateway.gateway : k => v.status }
}

output "gateway_role_arns" {
  description = "Map of gateway names to their IAM role ARNs"
  value       = { for k, v in aws_iam_role.gateway : k => v.arn }
}

output "gateway_target_ids" {
  description = "Map of gateway target names to their IDs"
  value       = { for k, v in aws_bedrockagentcore_gateway_target.gateway_target : k => v.target_id }
}

output "gateway_target_names" {
  description = "Map of gateway target names to their resource names"
  value       = { for k, v in aws_bedrockagentcore_gateway_target.gateway_target : k => v.name }
}

output "gateway_target_gateway_ids" {
  description = "Map of gateway target names to their associated gateway IDs"
  value       = { for k, v in aws_bedrockagentcore_gateway_target.gateway_target : k => v.gateway_identifier }
}

# =============================================================================
# MEMORY OUTPUTS
# =============================================================================

output "memory_ids" {
  description = "Map of memory names to their IDs"
  value       = { for k, v in awscc_bedrockagentcore_memory.memory : k => v.memory_id }
}

output "memory_arns" {
  description = "Map of memory names to their ARNs"
  value       = { for k, v in awscc_bedrockagentcore_memory.memory : k => v.memory_arn }
}

output "memory_statuses" {
  description = "Map of memory names to their statuses"
  value       = { for k, v in awscc_bedrockagentcore_memory.memory : k => v.status }
}

output "memory_role_arns" {
  description = "Map of memory names to their IAM role ARNs"
  value       = { for k, v in aws_iam_role.memory : k => v.arn }
}

# =============================================================================
