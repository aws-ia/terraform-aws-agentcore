# Lambda Function Outputs
output "lambda_function_arn" {
  description = "ARN of the Lambda function created as a gateway target"
  value       = aws_lambda_function.example_function.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function created as a gateway target"
  value       = aws_lambda_function.example_function.function_name
}

# Bedrock Agent Core Gateway Outputs
output "agent_gateway_id" {
  description = "ID of the created Bedrock AgentCore Gateway"
  value       = module.bedrock_agent_gateway.agent_gateway_id
}

output "agent_gateway_arn" {
  description = "ARN of the created Bedrock AgentCore Gateway"
  value       = module.bedrock_agent_gateway.agent_gateway_arn
}

output "agent_gateway_status" {
  description = "Status of the created Bedrock AgentCore Gateway"
  value       = module.bedrock_agent_gateway.agent_gateway_status
}

output "agent_gateway_url" {
  description = "URL of the created Bedrock AgentCore Gateway"
  value       = module.bedrock_agent_gateway.agent_gateway_url
}

output "agent_gateway_workload_identity_details" {
  description = "Workload identity details of the created Bedrock AgentCore Gateway"
  value       = module.bedrock_agent_gateway.agent_gateway_workload_identity_details
}

output "gateway_role_arn" {
  description = "ARN of the IAM role created for the Bedrock AgentCore Gateway"
  value       = module.bedrock_agent_gateway.gateway_role_arn
}

output "gateway_role_name" {
  description = "Name of the IAM role created for the Bedrock AgentCore Gateway"
  value       = module.bedrock_agent_gateway.gateway_role_name
}
