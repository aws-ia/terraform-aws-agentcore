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
  value       = merge(
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

# =============================================================================
# WORKLOAD IDENTITY OUTPUTS
# =============================================================================

output "workload_identity_arns" {
  description = "Map of workload identity names to their ARNs"
  value       = { for k, v in aws_bedrockagentcore_workload_identity.workload_identity : k => v.workload_identity_arn }
}

output "runtime_workload_identity_arns" {
  description = "Map of runtime names to the ARN of the workload identity AgentCore created for the runtime"
  value = merge(
    { for k, v in awscc_bedrockagentcore_runtime.runtime_code : k => v.workload_identity_details.workload_identity_arn },
    { for k, v in awscc_bedrockagentcore_runtime.runtime_container : k => v.workload_identity_details.workload_identity_arn }
  )
}

output "gateway_workload_identity_arns" {
  description = "Map of gateway names to the ARN of the workload identity AgentCore created for the gateway"
  value       = { for k, v in awscc_bedrockagentcore_gateway.gateway : k => v.workload_identity_details.workload_identity_arn }
}

# =============================================================================
# AGENT REGISTRY OUTPUTS
# =============================================================================

output "registry_ids" {
  description = "Map of registry names to their IDs"
  value       = { for k, v in awscc_agentregistry_registry.registry : k => v.registry_id }
}

output "registry_arns" {
  description = "Map of registry names to their ARNs"
  value       = { for k, v in awscc_agentregistry_registry.registry : k => v.registry_arn }
}

output "registry_statuses" {
  description = "Map of registry names to their statuses"
  value       = { for k, v in awscc_agentregistry_registry.registry : k => v.status }
}

output "registry_publisher_policy_arns" {
  description = "Map of registry names to the ARN of the IAM policy that lets a publisher write and submit records"
  value       = { for k, v in aws_iam_policy.registry_publisher : k => v.arn }
}

output "registry_publisher_role_arns" {
  description = "Map of registry names to the ARN of the publisher IAM role (created when trusted principals or services are given)"
  value       = { for k, v in aws_iam_role.registry_publisher : k => v.arn }
}

output "registry_record_ids" {
  description = "Map of '<registry name>/<record name>' to registry record IDs"
  value       = { for k, v in awscc_agentregistry_registry_record.record : k => v.record_id }
}

output "registry_record_arns" {
  description = "Map of '<registry name>/<record name>' to registry record ARNs"
  value       = { for k, v in awscc_agentregistry_registry_record.record : k => v.record_arn }
}
