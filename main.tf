# – Bedrock Agent Core Runtime (CODE) –

resource "awscc_bedrockagentcore_runtime" "runtime_code" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if config.source_type == "CODE"
  }

  agent_runtime_name = each.key
  description        = each.value.description
  role_arn           = each.value.execution_role_arn != null ? each.value.execution_role_arn : aws_iam_role.runtime[each.key].arn

  agent_runtime_artifact = {
    code_configuration = {
      code = {
        s3 = {
          bucket = each.value.code_s3_bucket != null ? each.value.code_s3_bucket : aws_s3_bucket.runtime[each.key].id
          prefix = each.value.code_s3_key != null ? each.value.code_s3_key : "source.zip"
        }
      }
      entry_point = each.value.code_entry_point
      runtime     = each.value.code_runtime
    }
  }

  network_configuration = {
    network_mode = each.value.execution_network_mode
    network_mode_config = each.value.execution_network_mode == "VPC" ? {
      security_groups = each.value.execution_network_config.security_groups
      subnets         = each.value.execution_network_config.subnets
    } : null
  }

  environment_variables = each.value.environment_variables
  tags                  = merge(local.merged_tags, each.value.tags)

  depends_on = [
    time_sleep.iam_role_propagation,
    terraform_data.build_trigger_code
  ]
}

# – Bedrock Agent Core Runtime (CONTAINER) –

resource "awscc_bedrockagentcore_runtime" "runtime_container" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if config.source_type == "CONTAINER"
  }

  agent_runtime_name = each.key
  description        = each.value.description
  role_arn           = each.value.execution_role_arn != null ? each.value.execution_role_arn : aws_iam_role.runtime[each.key].arn

  agent_runtime_artifact = {
    container_configuration = {
      container_uri = each.value.container_image_uri != null ? each.value.container_image_uri : "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/${aws_ecr_repository.runtime[each.key].name}:${each.value.container_image_tag}"
    }
  }

  network_configuration = {
    network_mode = each.value.execution_network_mode
    network_mode_config = each.value.execution_network_mode == "VPC" ? {
      security_groups = each.value.execution_network_config.security_groups
      subnets         = each.value.execution_network_config.subnets
    } : null
  }

  environment_variables = each.value.environment_variables
  tags                  = merge(local.merged_tags, each.value.tags)

  depends_on = [
    terraform_data.build_trigger_container,
    time_sleep.iam_role_propagation
  ]
}

# – Bedrock Agent Core Runtime Endpoint –

resource "awscc_bedrockagentcore_runtime_endpoint" "runtime" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if config.create_endpoint
  }

  name             = "${each.key}_endpoint"
  description      = each.value.endpoint_description
  agent_runtime_id = try(
    awscc_bedrockagentcore_runtime.runtime_code[each.key].agent_runtime_id,
    awscc_bedrockagentcore_runtime.runtime_container[each.key].agent_runtime_id
  )
  tags = merge(local.merged_tags, each.value.tags)
}

