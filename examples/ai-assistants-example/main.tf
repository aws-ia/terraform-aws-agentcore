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
  bucket = "bedrock-browser-recordings-${random_string.suffix.result}"

  tags = {
    Name        = "AI Assistant Browser Recordings"
    Environment = "example"
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
