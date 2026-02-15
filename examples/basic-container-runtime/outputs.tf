output "runtime_id" {
  value = module.terraform-aws-agentcore.runtime_ids["my_agent"]
}

output "endpoint_id" {
  value = module.terraform-aws-agentcore.endpoint_ids["my_agent"]
}

output "ecr_repository_url" {
  value = module.terraform-aws-agentcore.ecr_repository_urls["my_agent"]
}
