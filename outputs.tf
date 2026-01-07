# – Bedrock Agent Core Runtime Outputs –

output "agent_runtime_id" {
  description = "ID of the created Bedrock AgentCore Runtime"
  value       = local.agent_runtime_id
}

output "agent_runtime_arn" {
  description = "ARN of the created Bedrock AgentCore Runtime"
  value       = var.runtime_artifact_type == "container" ? try(awscc_bedrockagentcore_runtime.agent_runtime_container[0].agent_runtime_arn, null) : try(awscc_bedrockagentcore_runtime.agent_runtime_code[0].agent_runtime_arn, null)
}

output "agent_runtime_status" {
  description = "Status of the created Bedrock AgentCore Runtime"
  value       = var.runtime_artifact_type == "container" ? try(awscc_bedrockagentcore_runtime.agent_runtime_container[0].status, null) : try(awscc_bedrockagentcore_runtime.agent_runtime_code[0].status, null)
}

output "agent_runtime_version" {
  description = "Version of the created Bedrock AgentCore Runtime"
  value       = var.runtime_artifact_type == "container" ? try(awscc_bedrockagentcore_runtime.agent_runtime_container[0].agent_runtime_version, null) : try(awscc_bedrockagentcore_runtime.agent_runtime_code[0].agent_runtime_version, null)
}

output "agent_runtime_workload_identity_details" {
  description = "Workload identity details of the created Bedrock AgentCore Runtime"
  value       = var.runtime_artifact_type == "container" ? try(awscc_bedrockagentcore_runtime.agent_runtime_container[0].workload_identity_details, null) : try(awscc_bedrockagentcore_runtime.agent_runtime_code[0].workload_identity_details, null)
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

output "memory_kms_policy_arn" {
  description = "ARN of the KMS policy for memory encryption (only available when KMS is provided)"
  value       = local.create_kms_policy ? aws_iam_policy.memory_kms_policy[0].arn : null
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

output "gateway_interceptor_lambda_arns" {
  description = "List of Lambda function ARNs configured as gateway interceptors"
  value       = local.interceptor_lambda_arns
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

# – Bedrock Agent Core Code Interpreter Custom Outputs –

output "agent_code_interpreter_id" {
  description = "ID of the created Bedrock AgentCore Code Interpreter Custom"
  value       = try(awscc_bedrockagentcore_code_interpreter_custom.agent_code_interpreter[0].code_interpreter_id, null)
}

output "agent_code_interpreter_arn" {
  description = "ARN of the created Bedrock AgentCore Code Interpreter Custom"
  value       = try(awscc_bedrockagentcore_code_interpreter_custom.agent_code_interpreter[0].code_interpreter_arn, null)
}

output "agent_code_interpreter_status" {
  description = "Status of the created Bedrock AgentCore Code Interpreter Custom"
  value       = try(awscc_bedrockagentcore_code_interpreter_custom.agent_code_interpreter[0].status, null)
}

output "agent_code_interpreter_created_at" {
  description = "Creation timestamp of the created Bedrock AgentCore Code Interpreter Custom"
  value       = try(awscc_bedrockagentcore_code_interpreter_custom.agent_code_interpreter[0].created_at, null)
}

output "agent_code_interpreter_last_updated_at" {
  description = "Last update timestamp of the created Bedrock AgentCore Code Interpreter Custom"
  value       = try(awscc_bedrockagentcore_code_interpreter_custom.agent_code_interpreter[0].last_updated_at, null)
}

output "agent_code_interpreter_failure_reason" {
  description = "Failure reason if the Bedrock AgentCore Code Interpreter Custom failed"
  value       = try(awscc_bedrockagentcore_code_interpreter_custom.agent_code_interpreter[0].failure_reason, null)
}

output "code_interpreter_role_arn" {
  description = "ARN of the IAM role created for the Bedrock AgentCore Code Interpreter Custom"
  value       = try(aws_iam_role.code_interpreter_role[0].arn, null)
}

output "code_interpreter_role_name" {
  description = "Name of the IAM role created for the Bedrock AgentCore Code Interpreter Custom"
  value       = try(aws_iam_role.code_interpreter_role[0].name, null)
}

# – Bedrock Agent Core Browser Custom Outputs –

output "agent_browser_id" {
  description = "ID of the created Bedrock AgentCore Browser Custom"
  value       = try(awscc_bedrockagentcore_browser_custom.agent_browser[0].browser_id, null)
}

output "agent_browser_arn" {
  description = "ARN of the created Bedrock AgentCore Browser Custom"
  value       = try(awscc_bedrockagentcore_browser_custom.agent_browser[0].browser_arn, null)
}

output "agent_browser_status" {
  description = "Status of the created Bedrock AgentCore Browser Custom"
  value       = try(awscc_bedrockagentcore_browser_custom.agent_browser[0].status, null)
}

output "agent_browser_created_at" {
  description = "Creation timestamp of the created Bedrock AgentCore Browser Custom"
  value       = try(awscc_bedrockagentcore_browser_custom.agent_browser[0].created_at, null)
}

output "agent_browser_last_updated_at" {
  description = "Last update timestamp of the created Bedrock AgentCore Browser Custom"
  value       = try(awscc_bedrockagentcore_browser_custom.agent_browser[0].last_updated_at, null)
}

output "agent_browser_failure_reason" {
  description = "Failure reason if the Bedrock AgentCore Browser Custom failed"
  value       = try(awscc_bedrockagentcore_browser_custom.agent_browser[0].failure_reason, null)
}

output "browser_role_arn" {
  description = "ARN of the IAM role created for the Bedrock AgentCore Browser Custom"
  value       = try(aws_iam_role.browser_role[0].arn, null)
}

output "browser_role_name" {
  description = "Name of the IAM role created for the Bedrock AgentCore Browser Custom"
  value       = try(aws_iam_role.browser_role[0].name, null)
}

# Browser permissions outputs - Permission sets
output "browser_session_permissions" {
  description = "IAM permissions for managing browser sessions"
  value       = local.browser_session_perms
}

output "browser_stream_permissions" {
  description = "IAM permissions for browser streaming operations"
  value       = local.browser_stream_perms
}

output "browser_admin_permissions" {
  description = "IAM permissions for browser administration operations"
  value       = local.browser_admin_perms
}

output "browser_read_permissions" {
  description = "IAM permissions for reading browser information"
  value       = local.browser_read_perms
}

output "browser_list_permissions" {
  description = "IAM permissions for listing browser resources"
  value       = local.browser_list_perms
}

output "browser_use_permissions" {
  description = "IAM permissions for using browser functionality"
  value       = local.browser_use_perms
}

output "browser_full_access_permissions" {
  description = "Full access IAM permissions for all browser operations"
  value       = local.browser_full_access_perms
}

# Browser policy documents
output "browser_full_access_policy" {
  description = "Policy document for granting full access to Bedrock AgentCore Browser operations"
  value       = local.browser_full_access_policy_doc
}

output "browser_session_policy" {
  description = "Policy document for browser session management"
  value       = local.browser_session_policy_doc
}

output "browser_stream_policy" {
  description = "Policy document for browser streaming operations"
  value       = local.browser_stream_policy_doc
}

output "browser_admin_policy" {
  description = "Policy document for browser administration"
  value       = local.browser_admin_policy_doc
}

output "browser_read_policy" {
  description = "Policy document for reading browser information"
  value       = local.browser_read_policy_doc
}

output "browser_list_policy" {
  description = "Policy document for listing browser resources"
  value       = local.browser_list_policy_doc
}

output "browser_use_policy" {
  description = "Policy document for using browser functionality"
  value       = local.browser_use_policy_doc
}

# – Bedrock Agent Core Workload Identity Outputs –

output "workload_identity_id" {
  description = "ID of the created Bedrock AgentCore Workload Identity"
  value       = try(awscc_bedrockagentcore_workload_identity.workload_identity[0].id, null)
}

output "workload_identity_arn" {
  description = "ARN of the created Bedrock AgentCore Workload Identity"
  value       = try(awscc_bedrockagentcore_workload_identity.workload_identity[0].workload_identity_arn, null)
}

output "workload_identity_created_time" {
  description = "Creation timestamp of the created Bedrock AgentCore Workload Identity"
  value       = try(awscc_bedrockagentcore_workload_identity.workload_identity[0].created_time, null)
}

output "workload_identity_last_updated_time" {
  description = "Last update timestamp of the created Bedrock AgentCore Workload Identity"
  value       = try(awscc_bedrockagentcore_workload_identity.workload_identity[0].last_updated_time, null)
}

# – Bedrock Agent Core Gateway Target Outputs –

output "gateway_target_id" {
  description = "ID of the created Bedrock AgentCore Gateway Target"
  value       = try(aws_bedrockagentcore_gateway_target.gateway_target[0].target_id, null)
}

output "gateway_target_name" {
  description = "Name of the created Bedrock AgentCore Gateway Target"
  value       = try(aws_bedrockagentcore_gateway_target.gateway_target[0].name, null)
}

output "gateway_target_gateway_id" {
  description = "ID of the gateway that this target belongs to"
  value       = try(aws_bedrockagentcore_gateway_target.gateway_target[0].gateway_identifier, null)
}

# Code Interpreter permissions outputs - Permission sets
output "code_interpreter_session_permissions" {
  description = "IAM permissions for managing code interpreter sessions"
  value       = local.code_interpreter_session_perms
}

output "code_interpreter_invoke_permissions" {
  description = "IAM permissions for invoking code interpreter"
  value       = local.code_interpreter_invoke_perms
}

output "code_interpreter_admin_permissions" {
  description = "IAM permissions for code interpreter administration operations"
  value       = local.code_interpreter_admin_perms
}

output "code_interpreter_read_permissions" {
  description = "IAM permissions for reading code interpreter information"
  value       = local.code_interpreter_read_perms
}

output "code_interpreter_list_permissions" {
  description = "IAM permissions for listing code interpreter resources"
  value       = local.code_interpreter_list_perms
}

output "code_interpreter_use_permissions" {
  description = "IAM permissions for using code interpreter functionality"
  value       = local.code_interpreter_use_perms
}

output "code_interpreter_full_access_permissions" {
  description = "Full access IAM permissions for all code interpreter operations"
  value       = local.code_interpreter_full_access_perms
}

# Code Interpreter policy documents
output "code_interpreter_full_access_policy" {
  description = "Policy document for granting full access to Bedrock AgentCore Code Interpreter operations"
  value       = local.code_interpreter_full_access_policy_doc
}

output "code_interpreter_session_policy" {
  description = "Policy document for code interpreter session management"
  value       = local.code_interpreter_session_policy_doc
}

output "code_interpreter_invoke_policy" {
  description = "Policy document for code interpreter invocation operations"
  value       = local.code_interpreter_invoke_policy_doc
}

output "code_interpreter_admin_policy" {
  description = "Policy document for code interpreter administration"
  value       = local.code_interpreter_admin_policy_doc
}

output "code_interpreter_read_policy" {
  description = "Policy document for reading code interpreter information"
  value       = local.code_interpreter_read_policy_doc
}

output "code_interpreter_list_policy" {
  description = "Policy document for listing code interpreter resources"
  value       = local.code_interpreter_list_policy_doc
}

output "code_interpreter_use_policy" {
  description = "Policy document for using code interpreter functionality"
  value       = local.code_interpreter_use_policy_doc
}
