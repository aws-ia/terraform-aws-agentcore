# Identity provider for inbound JWT authorization on the runtime and both gateways.
# Replace with your own OpenID Connect provider by changing local.discovery_url and the client IDs.
resource "aws_cognito_user_pool" "agents" {
  name = "gateway-targets-example"
}

resource "aws_cognito_user_pool_client" "agents" {
  name            = "gateway-targets-example-client"
  user_pool_id    = aws_cognito_user_pool.agents.id
  generate_secret = false
}

locals {
  discovery_url = "https://${aws_cognito_user_pool.agents.endpoint}/.well-known/openid-configuration"
}

module "terraform-aws-agentcore" {
  source = "../.."
  # source = "aws-ia/agentcore/aws"
  # version = "x.x.x"

  project_prefix = "targets-example"
  debug          = true

  # HTTP agent with JWT inbound authorization, session lifecycle limits and custom headers
  runtimes = {
    support_agent = {
      source_type      = "CODE"
      code_source_path = "../basic-code-runtime/src"
      code_entry_point = ["agent.py"]
      code_runtime     = "PYTHON_3_11"
      description      = "HTTP agent fronted by agents-gateway"

      protocol_configuration = "HTTP"
      lifecycle_configuration = {
        idle_runtime_session_timeout = 600  # 10 minutes
        max_lifetime                 = 3600 # 1 hour
      }
      # Authorization may only be forwarded when a JWT authorizer is configured
      request_header_allowlist = ["Authorization", "X-Correlation-Id"]

      authorizer_configuration = {
        custom_jwt_authorizer = {
          discovery_url   = local.discovery_url
          allowed_clients = [aws_cognito_user_pool_client.agents.id]
        }
      }
    }
  }

  gateways = {
    # MCP gateway: tools from an MCP server, JWT inbound auth with a custom claim rule
    tools-gateway = {
      description     = "MCP tools behind JWT authorization"
      protocol_type   = "MCP"
      authorizer_type = "CUSTOM_JWT"
      authorizer_configuration = {
        custom_jwt_authorizer = {
          discovery_url   = local.discovery_url
          allowed_clients = [aws_cognito_user_pool_client.agents.id]
          custom_claims = [
            {
              inbound_token_claim_name       = "token_use"
              inbound_token_claim_value_type = "STRING"
              claim_match_operator           = "EQUALS"
              match_value_string             = "access"
            }
          ]
        }
      }
      protocol_configuration = {
        mcp = {
          instructions               = "Weather tools"
          search_type                = "SEMANTIC"
          supported_versions         = ["2025-11-25"]
          session_timeout_in_seconds = 1800 # 30 minutes
          enable_response_streaming  = true
        }
      }
      tags = {
        Component = "Gateway"
      }
    }

    # Gateway without a protocol type: the front door for HTTP targets (runtime, passthrough)
    agents-gateway = {
      description     = "HTTP front door for agents"
      protocol_type   = "NONE"
      authorizer_type = "CUSTOM_JWT"
      authorizer_configuration = {
        custom_jwt_authorizer = {
          discovery_url   = local.discovery_url
          allowed_clients = [aws_cognito_user_pool_client.agents.id]
        }
      }
      tags = {
        Component = "Gateway"
      }
    }
  }

  gateway_targets = {
    # MCP server with a static tool schema: no discovery call to the server at creation
    weather-mcp = {
      gateway_name = "tools-gateway"
      description  = "Remote MCP server with a static tool schema"
      type         = "MCP_SERVER"
      mcp_server_config = {
        endpoint          = "https://mcp.example.com/mcp"
        listing_mode      = "DEFAULT"
        resource_priority = 100
        tool_schema = {
          # Same shape as an MCP tools/list result
          inline_payload = jsonencode({
            tools = [
              {
                name        = "get_weather"
                description = "Get the current weather for a location"
                inputSchema = {
                  type = "object"
                  properties = {
                    location = {
                      type        = "string"
                      description = "City name"
                    }
                  }
                  required = ["location"]
                }
              }
            ]
          })
        }
      }
      metadata_configuration = {
        allowed_request_headers = ["x-correlation-id"]
      }
    }

    # The runtime above, reached as https://<gateway>/targets-example-support-agent/invocations
    support-agent = {
      gateway_name = "agents-gateway"
      description  = "Support agent runtime"
      type         = "AGENTCORE_RUNTIME"
      # No credential_provider_type: the gateway signs requests to the runtime with its own role
      agentcore_runtime_config = {
        runtime_name = "support_agent"
        qualifier    = "DEFAULT"
      }
      metadata_configuration = {
        allowed_request_headers  = ["x-correlation-id"]
        allowed_response_headers = ["x-request-id"]
      }
    }

    # External A2A agent reached through the same gateway, caller's JWT forwarded unchanged
    partner-agent = {
      gateway_name             = "agents-gateway"
      description              = "Partner A2A agent"
      type                     = "HTTP_PASSTHROUGH"
      credential_provider_type = "JWT_PASSTHROUGH"
      passthrough_config = {
        endpoint      = "https://partner-agent.example.com"
        protocol_type = "A2A"
        stickiness_configuration = {
          identifier = "$context.header.x-session-id"
          timeout    = 3600
        }
      }
    }
  }

  tags = {
    Environment = "development"
    Example     = "gateway-targets"
    ManagedBy   = "terraform"
  }
}
