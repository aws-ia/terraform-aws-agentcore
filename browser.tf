# – Bedrock Agent Core Browser Custom –

resource "awscc_bedrockagentcore_browser_custom" "browser" {
  for_each = var.browsers

  name               = each.key
  description        = each.value.description
  execution_role_arn = each.value.execution_role_arn != null ? each.value.execution_role_arn : aws_iam_role.browser[each.key].arn

  network_configuration = {
    network_mode = each.value.network_mode
    vpc_config = each.value.network_mode == "VPC" ? {
      security_groups = each.value.network_configuration.security_groups
      subnets         = each.value.network_configuration.subnets
    } : null
  }

  recording_config = each.value.recording_enabled ? {
    enabled = true
    s3_location = {
      bucket = each.value.recording_config.bucket
      prefix = each.value.recording_config.prefix
    }
  } : null

  tags = merge(local.merged_tags, each.value.tags)

  depends_on = [time_sleep.browser_iam_role_propagation]
}

