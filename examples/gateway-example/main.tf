#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################

# Create a simple Lambda function to be used as a gateway target
resource "aws_iam_role" "lambda_role" {
  name = "example_lambda_role_${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_lambda_function" "example_function" {
  #checkov:skip=CKV_AWS_272: Code signing validation not required for this example
  #checkov:skip=CKV_AWS_116: Dead Letter Queue not required for this example
  #checkov:skip=CKV_AWS_117: VPC configuration not required for this example
  filename      = "${path.module}/lambda_function.zip"
  function_name = "gateway_target_${random_id.suffix.hex}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  
  # Fix for CKV_AWS_115: Configure function-level concurrent execution limit
  reserved_concurrent_executions = 10
  
  # Fix for CKV_AWS_50: Enable X-Ray tracing
  tracing_config {
    mode = "Active"
  }

  # Create the zip file only when the Lambda function is created
  provisioner "local-exec" {
    command = <<EOF
      cd ${path.module} && \
      echo 'exports.handler = async (event) => {
        console.log("Event:", JSON.stringify(event, null, 2));
        return {
          statusCode: 200,
          body: JSON.stringify({ message: "Hello from Lambda!" }),
        };
      };' > index.js && \
      zip lambda_function.zip index.js
    EOF
  }
}

# Use the AgentCore module with gateway configuration
module "bedrock_agent_gateway" {
  source = "../.."
  
  # Enable gateway creation
  create_gateway = true
  
  # Gateway configuration
  gateway_name        = local.name
  gateway_description = "Example Bedrock Agent Gateway"
  

  # MCP is the only supported protocol type currently
  gateway_protocol_type = "MCP"

  gateway_authorizer_type = "AWS_IAM"

  # Optional protocol configuration
  gateway_protocol_configuration = {
    mcp = {
      instructions = "This gateway provides access to Lambda functions"
      search_type  = "SEMANTIC"
    }
  }

  gateway_allow_update_delete_permissions = true
  
  # Provide Lambda function ARNs that the gateway can invoke
  gateway_lambda_function_arns = [aws_lambda_function.example_function.arn]
  
  # Tags
  gateway_tags = {
    Environment = "example"
    Terraform   = "true"
  }
}

# Note: Gateway targets are created through the AWS console or AWS CLI
# The awscc_bedrockagentcore_gateway_target resource is not currently available
