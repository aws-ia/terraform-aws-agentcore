provider "aws" {
  region = local.region
}

provider "awscc" {
  region = local.region
}

# Get current account ID
data "aws_caller_identity" "current" {}

locals {
  region = "us-east-1"
  name   = "bedrock_code_runtime_example"
}

resource "random_id" "suffix" {
  byte_length = 4
}

# Create an S3 bucket for the agent runtime code
resource "aws_s3_bucket" "agent_runtime_code" {
  #checkov:skip=CKV2_AWS_62: "Event notifications not required for this example"
  #checkov:skip=CKV_AWS_18: "Access logging not required for this example"
  #checkov:skip=CKV_AWS_144: "Cross-region replication not required for this example"
  bucket = "bedrock-agent-runtime-code-${random_id.suffix.hex}"
  force_destroy = true # Allows terraform to delete the bucket even if it contains objects
}

# Block public access for the S3 bucket
resource "aws_s3_bucket_public_access_block" "agent_runtime_code_public_access_block" {
  bucket = aws_s3_bucket.agent_runtime_code.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Add lifecycle configuration to the S3 bucket
resource "aws_s3_bucket_lifecycle_configuration" "agent_runtime_code_lifecycle" {
  bucket = aws_s3_bucket.agent_runtime_code.id

  rule {
    id     = "cleanup-old-versions"
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

# Create KMS key for S3 bucket encryption
resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-policy-1",
    Statement = [
      {
        Sid    = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
          AWS = "*"
        },
        Action   = "kms:*",
        Resource = "*",
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/s3-bucket-key-${random_id.suffix.hex}"
  target_key_id = aws_kms_key.s3_key.key_id
}

# Set bucket versioning for the code bucket
resource "aws_s3_bucket_versioning" "agent_runtime_code_versioning" {
  bucket = aws_s3_bucket.agent_runtime_code.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption with KMS for the bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "agent_runtime_code_encryption" {
  bucket = aws_s3_bucket.agent_runtime_code.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Create a zip file containing the runtime code
resource "null_resource" "create_code_zip" {
  provisioner "local-exec" {
    command = <<EOF
      # Create a simple Python example file
      cat > ${path.module}/example_runtime.py <<EOL
import sys
import json
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def handler(event, context):
    """
    Main handler function for the Bedrock Agent Runtime
    """
    logger.info("Received event: %s", json.dumps(event))
    
    # Parse the request
    request_type = event.get('requestType', '')
    request_payload = event.get('payload', {})
    
    logger.info("Request type: %s", request_type)
    
    # Handle different request types
    if request_type == 'InvokeAgent':
        # Process agent invocation
        return {
            'response': {
                'message': 'Hello from the Bedrock Agent Code Runtime!',
                'timestamp': '2023-08-01T12:34:56Z',
                'data': request_payload
            }
        }
    else:
        # Handle unknown request type
        return {
            'response': {
                'error': f'Unknown request type: {request_type}',
                'status': 'error'
            }
        }

# For local testing
if __name__ == "__main__":
    # Sample event for testing
    test_event = {
        'requestType': 'InvokeAgent',
        'payload': {'query': 'test query'}
    }
    
    result = handler(test_event, None)
    print(json.dumps(result, indent=2))
EOL
      
      # Create a requirements.txt file
      cat > ${path.module}/requirements.txt <<EOL
boto3==1.28.0
botocore==1.31.0
requests==2.31.0
EOL
      
      # Zip the code
      zip -j ${path.module}/agent_runtime_code.zip ${path.module}/example_runtime.py ${path.module}/requirements.txt
    EOF
  }
}

# Upload the code to S3
resource "aws_s3_object" "agent_runtime_code_object" {
  depends_on = [null_resource.create_code_zip]
  bucket     = aws_s3_bucket.agent_runtime_code.id
  key        = "code/agent_runtime_code.zip"
  source     = "${path.module}/agent_runtime_code.zip"
  
  # Use the trigger of null_resource to force replacement when the zip changes
  etag = md5(join("", [for f in fileset("${path.module}", "*.py"): filemd5("${path.module}/${f}")]))
}

module "bedrock_agent_runtime" {
  source = "../.."
  
  # Make sure the code is uploaded before creating the agent runtime
  depends_on = [aws_s3_object.agent_runtime_code_object]

  # Enable agent runtime creation
  create_runtime = true
  
  # Runtime configuration for code-based runtime
  runtime_name        = local.name
  runtime_description = "Example Bedrock Agent Code Runtime"
  runtime_artifact_type = "code"
  
  # Code configuration
  runtime_code_s3_bucket = aws_s3_bucket.agent_runtime_code.bucket
  runtime_code_s3_prefix = aws_s3_object.agent_runtime_code_object.key
  runtime_code_entry_point = ["example_runtime.py"]  # Format based on CDK example
  runtime_code_runtime_type = "PYTHON_3_11"
  
  runtime_network_mode  = "PUBLIC"
  
  # Environment variables for the runtime
  runtime_environment_variables = {
    "LOG_LEVEL" = "INFO"
    "ENV"       = "example"
  }
  
  # Tags
  runtime_tags = {
    Environment = "example"
    Terraform   = "true"
  }
  
  # Enable agent runtime endpoint creation
  create_runtime_endpoint = true
  runtime_endpoint_name = "${local.name}_endpoint"
  runtime_endpoint_description = "Example Bedrock Agent Code Runtime Endpoint"
  
  # Tags for the endpoint
  runtime_endpoint_tags = {
    Environment = "example"
    Terraform   = "true"
  }
}

output "agent_runtime_id" {
  description = "ID of the created Bedrock Agent Runtime"
  value       = module.bedrock_agent_runtime.agent_runtime_id
}

output "agent_runtime_arn" {
  description = "ARN of the created Bedrock Agent Runtime"
  value       = module.bedrock_agent_runtime.agent_runtime_arn
}

output "agent_runtime_status" {
  description = "Status of the created Bedrock Agent Runtime"
  value       = module.bedrock_agent_runtime.agent_runtime_status
}

output "agent_runtime_endpoint_id" {
  description = "ID of the created Bedrock Agent Runtime Endpoint"
  value       = module.bedrock_agent_runtime.agent_runtime_endpoint_id
}

output "agent_runtime_endpoint_arn" {
  description = "ARN of the created Bedrock Agent Runtime Endpoint"
  value       = module.bedrock_agent_runtime.agent_runtime_endpoint_arn
}

output "agent_runtime_endpoint_status" {
  description = "Status of the created Bedrock Agent Runtime Endpoint"
  value       = module.bedrock_agent_runtime.agent_runtime_endpoint_status
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket containing the agent runtime code"
  value       = aws_s3_bucket.agent_runtime_code.bucket
}

output "s3_object_key" {
  description = "S3 key of the agent runtime code object"
  value       = aws_s3_object.agent_runtime_code_object.key
}
