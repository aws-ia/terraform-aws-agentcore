# – Bedrock Agent Core Workload Identity –

locals {
  create_workload_identity = var.create_workload_identity
  # Sanitize workload identity name to ensure it follows any required patterns
  sanitized_workload_identity_name = replace(var.workload_identity_name, "-", "_")
}

resource "awscc_bedrockagentcore_workload_identity" "workload_identity" {
  count = local.create_workload_identity ? 1 : 0

  name                                 = trimprefix("${local.solution_prefix}_${local.sanitized_workload_identity_name}", "_")
  allowed_resource_oauth_2_return_urls = var.workload_identity_allowed_resource_oauth_2_return_urls

  tags = var.workload_identity_tags != null ? [
    for k, v in var.workload_identity_tags : {
      key   = k
      value = v
    }
  ] : null
}
