# S3 buckets for module-managed artifacts
# One bucket per runtime for security isolation

resource "random_string" "bucket_suffix" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if (config.source_type == "CODE" && config.code_source_path != null) ||
       (config.source_type == "CONTAINER" && config.container_source_path != null)
  }

  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "runtime" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if (config.source_type == "CODE" && config.code_source_path != null) ||
       (config.source_type == "CONTAINER" && config.container_source_path != null)
  }

  bucket        = "${var.project_prefix}-${replace(each.key, "_", "-")}-${each.value.source_type == "CODE" ? "code" : "builds"}-${random_string.bucket_suffix[each.key].result}"
  force_destroy = true
  tags          = local.merged_tags
}

resource "aws_s3_bucket_versioning" "runtime" {
  for_each = aws_s3_bucket.runtime

  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "runtime" {
  for_each = aws_s3_bucket.runtime

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "runtime" {
  for_each = aws_s3_bucket.runtime

  bucket = each.value.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.runtimes[each.key].source_type == "CODE" ? 90 : 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
