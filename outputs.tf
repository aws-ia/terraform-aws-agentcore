# – Bedrock Agent Core Runtime Outputs –

output "agent_runtime_id" {
  description = "ID of the created Bedrock AgentCore Runtime"
  value       = try(awscc_bedrockagentcore_runtime.agent_runtime[0].agent_runtime_id, null)
}

output "agent_runtime_arn" {
  description = "ARN of the created Bedrock AgentCore Runtime"
  value       = try(awscc_bedrockagentcore_runtime.agent_runtime[0].agent_runtime_arn, null)
}

output "agent_runtime_status" {
  description = "Status of the created Bedrock AgentCore Runtime"
  value       = try(awscc_bedrockagentcore_runtime.agent_runtime[0].status, null)
}

output "agent_runtime_version" {
  description = "Version of the created Bedrock AgentCore Runtime"
  value       = try(awscc_bedrockagentcore_runtime.agent_runtime[0].agent_runtime_version, null)
}

output "agent_runtime_workload_identity_details" {
  description = "Workload identity details of the created Bedrock AgentCore Runtime"
  value       = try(awscc_bedrockagentcore_runtime.agent_runtime[0].workload_identity_details, null)
}

output "runtime_role_arn" {
  description = "ARN of the IAM role created for the Bedrock AgentCore Runtime"
  value       = try(aws_iam_role.runtime_role[0].arn, null)
}

output "runtime_role_name" {
  description = "Name of the IAM role created for the Bedrock AgentCore Runtime"
  value       = try(aws_iam_role.runtime_role[0].name, null)
}

# – Bedrock Agent Core Runtime Endpoint Outputs –

output "agent_runtime_endpoint_id" {
  description = "ID of the created Bedrock AgentCore Runtime Endpoint"
  value       = try(awscc_bedrockagentcore_runtime_endpoint.agent_runtime_endpoint[0].id, null)
}

output "agent_runtime_endpoint_arn" {
  description = "ARN of the created Bedrock AgentCore Runtime Endpoint"
  value       = try(awscc_bedrockagentcore_runtime_endpoint.agent_runtime_endpoint[0].agent_runtime_endpoint_arn, null)
}

output "agent_runtime_endpoint_status" {
  description = "Status of the created Bedrock AgentCore Runtime Endpoint"
  value       = try(awscc_bedrockagentcore_runtime_endpoint.agent_runtime_endpoint[0].status, null)
}

output "agent_runtime_endpoint_live_version" {
  description = "Live version of the created Bedrock AgentCore Runtime Endpoint"
  value       = try(awscc_bedrockagentcore_runtime_endpoint.agent_runtime_endpoint[0].live_version, null)
}

output "agent_runtime_endpoint_target_version" {
  description = "Target version of the created Bedrock AgentCore Runtime Endpoint"
  value       = try(awscc_bedrockagentcore_runtime_endpoint.agent_runtime_endpoint[0].target_version, null)
}

# – Bedrock Agent Core Memory Outputs –

output "agent_memory_id" {
  description = "ID of the created Bedrock AgentCore Memory"
  value       = try(awscc_bedrockagentcore_memory.agent_memory[0].memory_id, null)
}

output "agent_memory_arn" {
  description = "ARN of the created Bedrock AgentCore Memory"
  value       = try(awscc_bedrockagentcore_memory.agent_memory[0].memory_arn, null)
}

output "agent_memory_status" {
  description = "Status of the created Bedrock AgentCore Memory"
  value       = try(awscc_bedrockagentcore_memory.agent_memory[0].status, null)
}

output "agent_memory_created_at" {
  description = "Creation timestamp of the created Bedrock AgentCore Memory"
  value       = try(awscc_bedrockagentcore_memory.agent_memory[0].created_at, null)
}

output "agent_memory_updated_at" {
  description = "Last update timestamp of the created Bedrock AgentCore Memory"
  value       = try(awscc_bedrockagentcore_memory.agent_memory[0].updated_at, null)
}

output "memory_role_arn" {
  description = "ARN of the IAM role created for the Bedrock AgentCore Memory"
  value       = try(aws_iam_role.memory_role[0].arn, null)
}

output "memory_role_name" {
  description = "Name of the IAM role created for the Bedrock AgentCore Memory"
  value       = try(aws_iam_role.memory_role[0].name, null)
}

# Raw permission lists
output "memory_stm_write_permissions" {
  description = "IAM permissions for writing to Short-Term Memory (STM)"
  value       = local.stm_write_perms
}

output "memory_stm_read_permissions" {
  description = "IAM permissions for reading from Short-Term Memory (STM)"
  value       = local.stm_read_perms
}

output "memory_stm_delete_permissions" {
  description = "IAM permissions for deleting from Short-Term Memory (STM)"
  value       = local.stm_delete_perms
}

output "memory_ltm_read_permissions" {
  description = "IAM permissions for reading from Long-Term Memory (LTM)"
  value       = local.ltm_read_perms
}

output "memory_ltm_delete_permissions" {
  description = "IAM permissions for deleting from Long-Term Memory (LTM)"
  value       = local.ltm_delete_perms
}

output "memory_read_permissions" {
  description = "Combined IAM permissions for reading from both Short-Term Memory (STM) and Long-Term Memory (LTM)"
  value       = local.memory_read_perms
}

output "memory_delete_permissions" {
  description = "Combined IAM permissions for deleting from both Short-Term Memory (STM) and Long-Term Memory (LTM)"
  value       = local.memory_delete_perms
}

output "memory_admin_permissions" {
  description = "IAM permissions for memory administration operations"
  value       = local.memory_admin_perms
}

output "memory_full_access_permissions" {
  description = "Full access IAM permissions for all memory operations"
  value       = local.memory_full_access_perms
}

# Ready-to-use policy documents for granting to other resources
output "memory_stm_write_policy" {
  description = "Policy document for granting Short-Term Memory (STM) write permissions"
  value       = local.memory_stm_write_policy_doc
}

output "memory_read_policy" {
  description = "Policy document for granting read permissions to both STM and LTM"
  value       = local.memory_read_policy_doc
}

output "memory_stm_read_policy" {
  description = "Policy document for granting STM read permissions only"
  value       = local.memory_stm_read_policy_doc
}

output "memory_ltm_read_policy" {
  description = "Policy document for granting LTM read permissions only"
  value       = local.memory_ltm_read_policy_doc
}

output "memory_delete_policy" {
  description = "Policy document for granting delete permissions to both STM and LTM"
  value       = local.memory_delete_policy_doc
}

output "memory_stm_delete_policy" {
  description = "Policy document for granting STM delete permissions only"
  value       = local.memory_stm_delete_policy_doc
}

output "memory_ltm_delete_policy" {
  description = "Policy document for granting LTM delete permissions only"
  value       = local.memory_ltm_delete_policy_doc
}

output "memory_admin_policy" {
  description = "Policy document for granting control plane admin permissions"
  value       = local.memory_admin_policy_doc
}

output "memory_full_access_policy" {
  description = "Policy document for granting full access to all memory operations"
  value       = local.memory_full_access_policy_doc
}

# – Bedrock Agent Core Gateway Outputs –

output "agent_gateway_id" {
  description = "ID of the created Bedrock AgentCore Gateway"
  value       = try(awscc_bedrockagentcore_gateway.agent_gateway[0].gateway_identifier, null)
}

output "agent_gateway_arn" {
  description = "ARN of the created Bedrock AgentCore Gateway"
  value       = try(awscc_bedrockagentcore_gateway.agent_gateway[0].gateway_arn, null)
}

output "agent_gateway_status" {
  description = "Status of the created Bedrock AgentCore Gateway"
  value       = try(awscc_bedrockagentcore_gateway.agent_gateway[0].status, null)
}

output "agent_gateway_url" {
  description = "URL of the created Bedrock AgentCore Gateway"
  value       = try(awscc_bedrockagentcore_gateway.agent_gateway[0].gateway_url, null)
}

output "agent_gateway_workload_identity_details" {
  description = "Workload identity details of the created Bedrock AgentCore Gateway"
  value       = try(awscc_bedrockagentcore_gateway.agent_gateway[0].workload_identity_details, null)
}

output "agent_gateway_status_reasons" {
  description = "Status reasons of the created Bedrock AgentCore Gateway"
  value       = try(awscc_bedrockagentcore_gateway.agent_gateway[0].status_reasons, null)
}

output "gateway_role_arn" {
  description = "ARN of the IAM role created for the Bedrock AgentCore Gateway"
  value       = try(aws_iam_role.gateway_role[0].arn, null)
}

output "gateway_role_name" {
  description = "Name of the IAM role created for the Bedrock AgentCore Gateway"
  value       = try(aws_iam_role.gateway_role[0].name, null)
}

# – Cognito User Pool Outputs (for JWT Authentication Fallback) –

output "user_pool_id" {
  description = "ID of the Cognito User Pool created as JWT authentication fallback"
  value       = try(aws_cognito_user_pool.default[0].id, null)
}

output "user_pool_arn" {
  description = "ARN of the Cognito User Pool created as JWT authentication fallback"
  value       = try(aws_cognito_user_pool.default[0].arn, null)
}

output "user_pool_endpoint" {
  description = "Endpoint of the Cognito User Pool created as JWT authentication fallback"
  value       = local.create_user_pool ? "https://${local.user_pool_domain_name}.auth.${data.aws_region.current.region}.amazoncognito.com" : null
}

output "user_pool_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = try(aws_cognito_user_pool_client.default[0].id, null)
}

output "cognito_domain" {
  description = "Domain of the Cognito User Pool"
  value       = try(aws_cognito_user_pool_domain.default[0].domain, null)
}

output "cognito_discovery_url" {
  description = "OpenID Connect discovery URL for the Cognito User Pool"
  value       = local.create_user_pool ? "https://${local.user_pool_domain_name}.auth.${data.aws_region.current.region}.amazoncognito.com/.well-known/openid-configuration" : null
}

output "using_cognito_fallback" {
  description = "Whether the module is using a Cognito User Pool as fallback for JWT authentication"
  value       = local.create_user_pool
}
