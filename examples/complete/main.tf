# Example Lambda function for gateway target
resource "aws_iam_role" "lambda_role" {
  name = "complete-example-lambda-role"

  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [{
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        }
      }]
    }
  EOF
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/autogen/lambda.zip"

  source {
    content  = <<-EOT
      exports.handler = async (event) => {
        return {
          statusCode: 200,
          body: JSON.stringify({ message: "Hello from gateway target!" })
        };
      };
    EOT
    filename = "index.js"
  }
}

resource "aws_lambda_function" "gateway_target" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "complete-example-gateway-target"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  tracing_config {
    mode = "Active"
  }
}

module "terraform-aws-agentcore" {
  source = "../.."
  # source = "aws-ia/agentcore/aws"
  # version = "x.x.x"

  project_prefix = "complete-example"
  debug          = true

  # Multiple Runtimes: CODE + CONTAINER
  runtimes = {
    python_agent = {
      source_type      = "CODE"
      code_source_path = "../basic-code-runtime/src"
      code_entry_point = ["agent.py"]
      code_runtime     = "PYTHON_3_11"
      description      = "Python-based agent runtime"
      environment_variables = {
        LOG_LEVEL = "INFO"
      }
      create_endpoint = true
      tags = {
        RuntimeType = "CODE"
      }
    }

    container_agent = {
      source_type           = "CONTAINER"
      container_source_path = "../basic-container-runtime/src"
      description           = "Container-based agent runtime with STRANDS"
      environment_variables = {
        MODEL_ID = "anthropic.claude-3-sonnet-20240229-v1:0"
      }
      create_endpoint = true
      tags = {
        RuntimeType = "CONTAINER"
      }
    }
  }

  # Memory with Built-in Strategies (one strategy per memory)
  memories = {
    semantic_memory = {
      description           = "Semantic memory for factual knowledge"
      event_expiry_duration = 90
      strategies = [
        {
          semantic_memory_strategy = {
            name        = "semantic_facts"
            description = "Extract factual knowledge from conversations"
            namespaces  = ["/strategies/{memoryStrategyId}/actors/{actorId}"]
          }
        }
      ]
      tags = {
        Component = "Memory"
      }
    }
  }

  # Gateway for MCP Protocol
  gateways = {
    mcp-gateway = {
      description       = "Gateway for Model Context Protocol connections"
      protocol_type     = "MCP"
      authorizer_type   = "AWS_IAM"
      protocol_configuration = {
        mcp = {
          instructions        = "Gateway for external service integration"
          search_type         = "SEMANTIC"
          supported_versions  = ["2025-11-25"]
        }
      }
      tags = {
        Component = "Gateway"
      }
    }
  }

  # Gateway Targets for Lambda integration
  gateway_targets = {
    lambda-target = {
      gateway_name             = "mcp-gateway"
      description              = "Lambda function integration"
      credential_provider_type = "GATEWAY_IAM_ROLE"
      type                     = "LAMBDA"
      lambda_config = {
        lambda_arn       = aws_lambda_function.gateway_target.arn
        tool_schema_type = "INLINE"
        inline_schema = {
          name        = "process_request"
          description = "Process requests via Lambda"
          input_schema = {
            type        = "object"
            description = "Request input"
            properties = [{
              name        = "query"
              type        = "string"
              description = "Query to process"
              required    = true
            }]
          }
          output_schema = {
            type = "object"
            properties = [{
              name     = "result"
              type     = "string"
              required = true
            }]
          }
        }
      }
    }
  }

  # Browser for Web Interaction
  browsers = {
    web_browser = {
      description       = "Custom browser for web interaction"
      network_mode      = "PUBLIC"
      recording_enabled = false  # Disabled - would need S3 bucket
      tags = {
        Component = "Browser"
      }
    }
  }

  # Code Interpreter for Secure Execution
  code_interpreters = {
    python_interpreter = {
      description  = "Secure Python code execution environment"
      network_mode = "SANDBOX"
      tags = {
        Component = "CodeInterpreter"
      }
    }
  }

  tags = {
    Environment = "development"
    Example     = "complete"
    ManagedBy   = "terraform"
  }
}
