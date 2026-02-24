# – Bedrock Agent Core Code Interpreter Custom –

resource "awscc_bedrockagentcore_code_interpreter_custom" "code_interpreter" {
  for_each = var.code_interpreters

  name               = each.key
  description        = each.value.description
  execution_role_arn = each.value.execution_role_arn != null ? each.value.execution_role_arn : aws_iam_role.code_interpreter[each.key].arn

  network_configuration = {
    network_mode = each.value.network_mode
    vpc_config = each.value.network_mode == "VPC" ? {
      security_groups = each.value.network_configuration.security_groups
      subnets         = each.value.network_configuration.subnets
    } : null
  }

  tags = merge(local.merged_tags, each.value.tags)

  depends_on = [time_sleep.code_interpreter_iam_role_propagation]
}

