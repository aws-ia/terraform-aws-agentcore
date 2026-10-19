# Example Lambda function that backs both gateway targets (the tools the policies govern)
resource "aws_iam_role" "lambda_role" {
  name = "gateway-policy-example-lambda-role"

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
      // AgentCore Gateway passes the tool name as <target name>___<tool name>
      exports.handler = async (event, context) => {
        const custom = (context.clientContext && context.clientContext.custom) || {};
        const fullName = custom.bedrockAgentCoreToolName || "";
        const tool = fullName.includes("___") ? fullName.split("___").pop() : fullName;

        if (tool === "get_order") {
          return { order_id: event.order_id, status: "shipped", total: 120 };
        }
        if (tool === "refund_order") {
          return { order_id: event.order_id, refunded: event.amount, reason: event.reason || "unspecified" };
        }
        return { error: "Unknown tool: " + tool };
      };
    EOT
    filename = "index.js"
  }
}

resource "aws_lambda_function" "orders" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "gateway-policy-example-orders"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  tracing_config {
    mode = "Active"
  }
}

# Used to scope the lookup policy to IAM callers from this account
data "aws_caller_identity" "current" {}

module "terraform-aws-agentcore" {
  source = "../.."
  # source = "aws-ia/agentcore/aws"
  # version = "x.x.x"

  project_prefix = "policy-example"
  debug          = true

  # Policy engine: Cedar and Dogwood policies for the orders gateway.
  # {{gateway:<name>}} and {{target:<name>}} resolve to the gateway ARN and the
  # gateway target name once they exist (gateway tools are named <target name>___<tool>).
  policy_engines = {
    orders_policy_engine = {
      description = "Authorizes tool calls on the orders gateway"
      policies = [
        {
          # An unconstrained principal is reported as "Overly Permissive" by the Cedar
          # analyzer and rejected under FAIL_ON_ANY_FINDINGS, so scope the permit to IAM
          # callers of this account (IAM principals carry their ARN in the id attribute).
          name        = "AllowOrderLookup"
          description = "IAM callers from this account may look up an order"
          statement   = <<-EOT
            permit(
              principal is AgentCore::IamEntity,
              action == AgentCore::Action::"{{target:orders-lookup}}___get_order",
              resource == AgentCore::Gateway::"{{gateway:orders-gateway}}"
            ) when { principal.id like "*:${data.aws_caller_identity.current.account_id}:*" };
          EOT
        },
        {
          # The analyzer reports a forbid on an action that no plain Cedar permit allows as
          # "Overly Restrictive" (the temporal permit below does not count), which is normal
          # for an observation policy: IGNORE_ALL_FINDINGS keeps the analyzer out of the way
          # while the policy collects data in LOG_ONLY mode.
          name             = "FlagLargeRefunds"
          description      = "Refunds above 500 are denied once promoted to ACTIVE; LOG_ONLY observes first"
          enforcement_mode = "LOG_ONLY"
          validation_mode  = "IGNORE_ALL_FINDINGS"
          statement        = <<-EOT
            forbid(
              principal,
              action == AgentCore::Action::"{{target:orders-refund}}___refund_order",
              resource == AgentCore::Gateway::"{{gateway:orders-gateway}}"
            ) when { context.input.amount > 500 };
          EOT
        },
        {
          name        = "RefundOnlyAfterLookup"
          description = "Temporal rule: a refund needs a successful order lookup earlier in the same policy session"
          language    = "DOGWOOD"
          statement   = <<-EOT
            permit(
              principal,
              action == AgentCore::Action::"{{target:orders-refund}}___refund_order",
              resource == AgentCore::Gateway::"{{gateway:orders-gateway}}"
            )
            when temporal {
              formerly within 10m AgentCore::Action::"{{target:orders-lookup}}___get_order"::response {
                eventResource: resource
              }
            };
          EOT
        }
      ]
      tags = {
        Component = "Policy"
      }
    }
  }

  # Gateway with the policy engine attached in ENFORCE mode
  gateways = {
    orders-gateway = {
      description     = "Orders tools governed by Policy in AgentCore"
      protocol_type   = "MCP"
      authorizer_type = "AWS_IAM"
      protocol_configuration = {
        mcp = {
          instructions       = "Order lookup and refund tools"
          search_type        = "SEMANTIC"
          supported_versions = ["2025-11-25"]
        }
      }
      policy_engine_configuration = {
        policy_engine_name = "orders_policy_engine"
        mode               = "ENFORCE"
      }
      tags = {
        Component = "Gateway"
      }
    }
  }

  # One target per tool (the module's inline schema describes a single tool per target)
  gateway_targets = {
    orders-lookup = {
      gateway_name             = "orders-gateway"
      description              = "Order lookup tool"
      credential_provider_type = "GATEWAY_IAM_ROLE"
      type                     = "LAMBDA"
      lambda_config = {
        lambda_arn       = aws_lambda_function.orders.arn
        tool_schema_type = "INLINE"
        inline_schema = {
          name        = "get_order"
          description = "Look up an order by ID"
          input_schema = {
            type = "object"
            properties = [
              {
                name        = "order_id"
                type        = "string"
                description = "Order ID"
                required    = true
              }
            ]
          }
          output_schema = {
            type = "object"
            properties = [
              {
                name        = "status"
                type        = "string"
                description = "Fulfilment status"
                required    = true
              }
            ]
          }
        }
      }
    }

    orders-refund = {
      gateway_name             = "orders-gateway"
      description              = "Order refund tool"
      credential_provider_type = "GATEWAY_IAM_ROLE"
      type                     = "LAMBDA"
      lambda_config = {
        lambda_arn       = aws_lambda_function.orders.arn
        tool_schema_type = "INLINE"
        inline_schema = {
          name        = "refund_order"
          description = "Refund an order"
          input_schema = {
            type = "object"
            properties = [
              {
                name        = "order_id"
                type        = "string"
                description = "Order ID"
                required    = true
              },
              {
                name        = "amount"
                type        = "integer"
                description = "Refund amount in whole currency units"
                required    = true
              },
              {
                name        = "reason"
                type        = "string"
                description = "Why the order is refunded"
                required    = false
              }
            ]
          }
          # NOTE: with several targets, every inline_schema must have the same shape
          # (the module types schema properties as list(any))
          output_schema = {
            type = "object"
            properties = [
              {
                name        = "refunded"
                type        = "integer"
                description = "Refunded amount"
                required    = true
              }
            ]
          }
        }
      }
    }
  }

  tags = {
    Environment = "development"
    Example     = "gateway-policy"
    ManagedBy   = "terraform"
  }
}
