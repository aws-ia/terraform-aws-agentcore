#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################

# Create a simple Lambda function to be used as a gateway target
# First, create the Lambda ZIP file using the archive_file resource
resource "local_file" "lambda_code" {
  filename = "${path.module}/index.js"
  content  = <<-EOT
    exports.handler = async (event) => {
      console.log("Event:", JSON.stringify(event, null, 2));
      return {
        statusCode: 200,
        body: JSON.stringify({ message: "Hello from Lambda!" }),
      };
    };
  EOT
}

resource "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = local_file.lambda_code.filename
  output_path = "${path.module}/lambda_function.zip"
}

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
  filename      = archive_file.lambda_zip.output_path
  function_name = "gateway_target_${random_id.suffix.hex}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  
  # Fix for CKV_AWS_115: Configure function-level concurrent execution limit
  reserved_concurrent_executions = 10
  
  # Fix for CKV_AWS_50: Enable X-Ray tracing
  tracing_config {
    mode = "Active"
  }
  
  source_code_hash = archive_file.lambda_zip.output_base64sha256
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
  
  # Enable and configure a gateway target using the Lambda function
  create_gateway_target = true
  gateway_target_name = "example-lambda-target"
  gateway_target_description = "Example Lambda function target"
  gateway_target_credential_provider_type = "GATEWAY_IAM_ROLE"
  
  gateway_target_type = "LAMBDA"
  gateway_target_lambda_config = {
    lambda_arn = aws_lambda_function.example_function.arn
    tool_schema_type = "INLINE"
    inline_schema = {
      name = "example_tool"
      description = "Example tool to demonstrate gateway targets"
      
      input_schema = {
        type = "object"
        description = "Input schema for the example tool"
        properties = [
          {
            name = "query"
            type = "string"
            description = "Query to process"
            required = true
          },
          {
            name = "options"
            type = "object"
            nested_properties = [
              {
                name = "detailed"
                type = "boolean"
                description = "Whether to return detailed results"
              }
            ]
          }
        ]
      }
      
      output_schema = {
        type = "object"
        description = "Output schema for the example tool"
        properties = [
          {
            name = "result"
            type = "string"
            description = "Processing result"
            required = true
          },
          {
            name = "metadata"
            type = "object"
            properties = [
              {
                name = "timestamp"
                type = "string"
                description = "Timestamp of the response"
              }
            ]
          }
        ]
      }
    }
  }
  
  # Tags
  gateway_tags = {
    Environment = "example"
    Terraform   = "true"
  }
}

# Now the gateway target is created using the module's aws_bedrockagentcore_gateway_target resource
