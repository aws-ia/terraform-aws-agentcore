provider "aws" {
  region = local.region
}

provider "awscc" {
  region = local.region
}

locals {
  region = "us-east-1"
  name   = "bedrock_agent_runtime_example"
}

resource "random_id" "suffix" {
  byte_length = 4
}

# Create an ECR repository for the agent runtime container
resource "aws_ecr_repository" "agent_runtime" {
  name = "bedrock/agent-runtime-${random_id.suffix.hex}"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Get ECR login token
data "aws_ecr_authorization_token" "token" {}

# Build and push Docker image to ECR
resource "null_resource" "docker_image" {
  depends_on = [aws_ecr_repository.agent_runtime]

  triggers = {
    dockerfile_hash = filesha256("${path.module}/Dockerfile")
    app_hash        = filesha256("${path.module}/app.py")
    requirements_hash = filesha256("${path.module}/requirements.txt")
  }

  provisioner "local-exec" {
    # Use bash explicitly and source profile to ensure Docker is in PATH
    interpreter = ["/bin/bash", "-c"]
    command = <<EOF
      # Source profile to ensure Docker is in PATH
      source ~/.bash_profile || source ~/.profile || true
      
      # Check if Docker is available
      if ! command -v docker &> /dev/null; then
        echo "Docker is not installed or not in PATH. Please install Docker and try again."
        exit 1
      fi
      
      # Login to ECR
      aws ecr get-login-password --region ${local.region} | docker login --username AWS --password-stdin ${data.aws_ecr_authorization_token.token.proxy_endpoint}
      
      # Build the Docker image
      docker build -t ${aws_ecr_repository.agent_runtime.repository_url}:latest ${path.module}
      
      # Push the image to ECR
      docker push ${aws_ecr_repository.agent_runtime.repository_url}:latest
    EOF
  }
}

module "bedrock_agent_runtime" {
  source = "../.."
  
  # Make sure the Docker image is pushed before creating the agent runtime
  depends_on = [null_resource.docker_image]

  # Enable agent runtime creation
  create_runtime = true
  
  # Runtime configuration
  runtime_name        = local.name
  runtime_description = "Example Bedrock Agent Runtime"
  runtime_container_uri = "${aws_ecr_repository.agent_runtime.repository_url}:latest"
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
  runtime_endpoint_description = "Example Bedrock Agent Runtime Endpoint"
  
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

output "aws_ecr_repository_url" {
  description = "URL of the ECR repository for the agent runtime container"
  value       = aws_ecr_repository.agent_runtime.repository_url
}
