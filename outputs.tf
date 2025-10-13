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
