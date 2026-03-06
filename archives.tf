# Archive and upload module-managed runtime sources
# NOTE: CodeBuild automatically handles ARM64 dependency installation for CODE runtimes.
# Your source code is uploaded to S3, CodeBuild installs dependencies, and outputs the final package.

data "archive_file" "runtime_source" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if(config.source_type == "CODE" && config.code_source_path != null) ||
    (config.source_type == "CONTAINER" && config.container_source_path != null)
  }

  type        = "zip"
  source_dir  = "${path.root}/${each.value.source_type == "CODE" ? each.value.code_source_path : each.value.container_source_path}"
  output_path = "${path.module}/.terraform/tmp/${each.key}.zip"
}

# Upload source code (without dependencies) for CodeBuild
resource "aws_s3_object" "runtime_source_input" {
  for_each = data.archive_file.runtime_source

  bucket = aws_s3_bucket.runtime[each.key].id
  key    = "source-input.zip"
  source = each.value.output_path
  etag   = each.value.output_md5

  lifecycle {
    precondition {
      condition     = var.runtimes[each.key].source_type != "CODE" || each.value.output_size <= 262144000
      error_message = "CODE runtime '${each.key}' zip file exceeds 250MB limit (${each.value.output_size} bytes). AgentCore CODE runtimes have a 250MB maximum."
    }
  }
}
