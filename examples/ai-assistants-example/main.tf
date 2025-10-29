provider "random" {}
provider "aws" {}
provider "awscc" {}

# Create a random suffix for resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create an S3 bucket for browser recordings
resource "aws_s3_bucket" "browser_recordings" {
  # checkov:skip=CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
  bucket = "bedrock-browser-recordings-${random_string.suffix.result}"

  tags = {
    Name        = "AI Assistant Browser Recordings"
    Environment = "example"
  }
}

# Enable versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "browser_recordings" {
  bucket = aws_s3_bucket.browser_recordings.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for the S3 bucket with KMS
resource "aws_kms_key" "browser_recordings" {
  description             = "KMS key for browser recordings bucket encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      }
    ]
  })
}

# Get the current AWS account ID
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_server_side_encryption_configuration" "browser_recordings" {
  bucket = aws_s3_bucket.browser_recordings.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.browser_recordings.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "browser_recordings" {
  bucket                  = aws_s3_bucket.browser_recordings.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable access logging for the S3 bucket
resource "aws_s3_bucket" "access_logs" {
  # checkov:skip=CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
  # checkov:skip=CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
  bucket = "bedrock-browser-logs-${random_string.suffix.result}"
  
  tags = {
    Name        = "AI Assistant Browser Logs"
    Environment = "example"
  }
}

# Enable versioning for the access logs bucket
resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for access logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.browser_recordings.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Add lifecycle configuration for access logs bucket
resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "logs-lifecycle"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket                  = aws_s3_bucket.access_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "browser_recordings" {
  bucket = aws_s3_bucket.browser_recordings.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "browser-recordings-logs/"
}

# Add lifecycle configuration 
resource "aws_s3_bucket_lifecycle_configuration" "browser_recordings" {
  bucket = aws_s3_bucket.browser_recordings.id

  rule {
    id     = "recordings-lifecycle"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    
    # Add abort incomplete multipart uploads rule
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Add event notification for the S3 bucket (CKV2_AWS_62)
resource "aws_sns_topic" "browser_recordings_events" {
  name = "browser-recordings-events-${random_string.suffix.result}"
  kms_master_key_id = aws_kms_key.browser_recordings.id
}

resource "aws_s3_bucket_notification" "browser_recordings" {
  bucket = aws_s3_bucket.browser_recordings.id

  topic {
    topic_arn     = aws_sns_topic.browser_recordings_events.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".mp4"
  }
}

# Apply the agentcore module
module "ai_assistants" {
  source = "../.."

  # Configure Browser Custom resource
  create_browser            = true
  browser_name              = "AiAssistantBrowser"
  browser_description       = "Browser for AI assistant agent"
  browser_network_mode      = "PUBLIC"
  browser_recording_enabled = true
  browser_recording_config = {
    bucket = aws_s3_bucket.browser_recordings.bucket
    prefix = "recordings/"
  }
  browser_tags = {
    Environment = "example"
    Component   = "browser"
  }

  # Configure Code Interpreter Custom resource
  create_code_interpreter       = true
  code_interpreter_name         = "AiAssistantCodeInterpreter"
  code_interpreter_description  = "Code interpreter for AI assistant agent"
  code_interpreter_network_mode = "SANDBOX"
  code_interpreter_tags = {
    Environment = "example"
    Component   = "code-interpreter"
  }
}

# Outputs
output "browser_id" {
  description = "ID of the created Bedrock AgentCore Browser Custom"
  value       = module.ai_assistants.agent_browser_id
}

output "browser_arn" {
  description = "ARN of the created Bedrock AgentCore Browser Custom"
  value       = module.ai_assistants.agent_browser_arn
}

output "code_interpreter_id" {
  description = "ID of the created Bedrock AgentCore Code Interpreter Custom"
  value       = module.ai_assistants.agent_code_interpreter_id
}

output "code_interpreter_arn" {
  description = "ARN of the created Bedrock AgentCore Code Interpreter Custom"
  value       = module.ai_assistants.agent_code_interpreter_arn
}

output "memory_id" {
  description = "ID of the created Bedrock AgentCore Memory"
  value       = module.ai_assistants.agent_memory_id
}

output "browser_recordings_bucket" {
  description = "S3 bucket for browser recordings"
  value       = aws_s3_bucket.browser_recordings.bucket
}
