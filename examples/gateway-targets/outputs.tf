output "runtime_ids" {
  description = "Map of runtime names to their IDs"
  value       = module.terraform-aws-agentcore.runtime_ids
}

output "gateway_urls" {
  description = "Map of gateway names to their URLs"
  value       = module.terraform-aws-agentcore.gateway_urls
}

output "gateway_target_names" {
  description = "Map of gateway target names to their resource names (HTTP targets are reached at <gateway url>/<target name>/...)"
  value       = module.terraform-aws-agentcore.gateway_target_names
}

output "gateway_target_ids" {
  description = "Map of gateway target names to their IDs"
  value       = module.terraform-aws-agentcore.gateway_target_ids
}

output "discovery_url" {
  description = "OpenID Connect discovery URL of the example identity provider"
  value       = local.discovery_url
}

output "client_id" {
  description = "Client ID accepted by the runtime and the gateways"
  value       = aws_cognito_user_pool_client.agents.id
}
