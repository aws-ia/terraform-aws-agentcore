output "runtime_id" {
  value = module.terraform-aws-agentcore.runtime_ids["my_agent"]
}

output "endpoint_id" {
  value = module.terraform-aws-agentcore.endpoint_ids["my_agent"]
}
