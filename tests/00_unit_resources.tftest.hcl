# Root-module unit tests with mocked providers. Each run feeds the module its
# variables directly and asserts on the resources the module renders: placeholder
# resolution, policy definitions, IAM statements, gateway and target blocks,
# registry descriptors. No AWS credentials or resources are needed.
#
#   terraform test -filter=tests/00_unit_resources.tftest.hcl

mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }
  mock_data "aws_region" {
    defaults = {
      id     = "us-east-1"
      name   = "us-east-1"
      region = "us-east-1"
    }
  }
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-role"
    }
  }
  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/mock-policy"
    }
  }
  mock_resource "aws_lambda_function" {
    defaults = {
      arn = "arn:aws:lambda:us-east-1:123456789012:function:mock-function"
    }
  }
  mock_resource "aws_bedrockagentcore_gateway" {
    defaults = {
      gateway_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/mock-http-gateway-abcdefghij"
      gateway_id  = "mock-http-gateway-abcdefghij"
      gateway_url = "https://mock-http-gateway-abcdefghij.gateway.bedrock-agentcore.us-east-1.amazonaws.com"
      workload_identity_details = [{
        workload_identity_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:workload-identity-directory/default/workload-identity/mock-http-gateway-abcdefghij"
      }]
    }
  }
  mock_resource "aws_bedrockagentcore_workload_identity" {
    defaults = {
      workload_identity_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:workload-identity-directory/default/workload-identity/mock-identity"
    }
  }
}

mock_provider "awscc" {
  mock_resource "awscc_bedrockagentcore_runtime" {
    defaults = {
      agent_runtime_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/mock_runtime-abcdefghij"
      agent_runtime_id  = "mock_runtime-abcdefghij"
      workload_identity_details = {
        workload_identity_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:workload-identity-directory/default/workload-identity/mock_runtime-abcdefghij"
      }
    }
  }
  mock_resource "awscc_bedrockagentcore_gateway" {
    defaults = {
      gateway_arn        = "arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/mock-gateway-abcdefghij"
      gateway_identifier = "mock-gateway-abcdefghij"
      gateway_url        = "https://mock-gateway-abcdefghij.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp"
      workload_identity_details = {
        workload_identity_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:workload-identity-directory/default/workload-identity/mock-gateway-abcdefghij"
      }
    }
  }
  mock_resource "awscc_bedrockagentcore_policy_engine" {
    defaults = {
      policy_engine_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:policy-engine/mock_engine-abcdefghij"
      policy_engine_id  = "mock_engine-abcdefghij"
    }
  }
  mock_resource "awscc_bedrockagentcore_configuration_bundle" {
    defaults = {
      bundle_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:configuration-bundle/mock_bundle-abcdefghij"
      bundle_id  = "mock_bundle-abcdefghij"
      version_id = "12345678-1234-1234-1234-123456789012"
    }
  }
  mock_resource "awscc_agentregistry_registry" {
    defaults = {
      registry_arn = "arn:aws:agent-registry:us-east-1:123456789012:registry/abcdefghijkl"
      registry_id  = "abcdefghijkl"
    }
  }
}

mock_provider "time" {}

variables {
  project_prefix = "unit"
  debug          = false
}

# ─── Policy engines: placeholder resolution, Cedar vs Dogwood, gateway attachment, IAM ───

run "policy_engine_rendering" {
  command = apply

  variables {
    policy_engines = {
      orders_engine = {
        description = "Orders policies"
        policies = [
          {
            name      = "AllowLookup"
            statement = "permit(principal, action == AgentCore::Action::\"{{target:orders}}___get_order\", resource == AgentCore::Gateway::\"{{gateway:orders-gateway}}\");"
          },
          {
            name             = "RefundAfterLookup"
            language         = "DOGWOOD"
            enforcement_mode = "LOG_ONLY"
            validation_mode  = "IGNORE_ALL_FINDINGS"
            statement        = "permit(principal, action == AgentCore::Action::\"{{target:orders}}___refund_order\", resource == AgentCore::Gateway::\"{{gateway:orders-gateway}}\") when temporal { formerly within 5m AgentCore::Action::\"{{target:orders}}___get_order\"::request { eventResource: resource } };"
          },
          {
            name      = "KeepsUnknownBraces"
            statement = "permit(principal, action, resource is AgentCore::Gateway) when { context.input.note like \"{{not-a-placeholder}}*\" };"
          }
        ]
      }
    }

    gateways = {
      orders-gateway = {
        policy_engine_configuration = {
          policy_engine_name = "orders_engine"
          mode               = "LOG_ONLY"
        }
      }
    }

    gateway_targets = {
      orders = {
        gateway_name             = "orders-gateway"
        type                     = "LAMBDA"
        credential_provider_type = "GATEWAY_IAM_ROLE"
        lambda_config = {
          lambda_arn       = "arn:aws:lambda:us-east-1:123456789012:function:orders"
          tool_schema_type = "INLINE"
          inline_schema = {
            name        = "get_order"
            description = "Look up an order"
            input_schema = {
              type = "object"
              properties = [{
                name        = "order_id"
                type        = "string"
                description = "Order ID"
                required    = true
              }]
            }
          }
        }
      }
    }
  }

  assert {
    condition     = strcontains(awscc_bedrockagentcore_policy.policy["orders_engine/AllowLookup"].definition.cedar.statement, "AgentCore::Action::\"unit-orders___get_order\"")
    error_message = "{{target:orders}} should resolve to the prefixed gateway target name"
  }

  assert {
    condition     = strcontains(awscc_bedrockagentcore_policy.policy["orders_engine/AllowLookup"].definition.cedar.statement, "AgentCore::Gateway::\"arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/mock-gateway-abcdefghij\"")
    error_message = "{{gateway:orders-gateway}} should resolve to the gateway ARN"
  }

  assert {
    condition     = strcontains(awscc_bedrockagentcore_policy.policy["orders_engine/RefundAfterLookup"].definition.policy.statement, "when temporal") && strcontains(awscc_bedrockagentcore_policy.policy["orders_engine/RefundAfterLookup"].definition.policy.statement, "unit-orders___refund_order")
    error_message = "DOGWOOD statements should be sent in definition.policy with placeholders resolved"
  }

  assert {
    condition     = awscc_bedrockagentcore_policy.policy["orders_engine/RefundAfterLookup"].enforcement_mode == "LOG_ONLY" && awscc_bedrockagentcore_policy.policy["orders_engine/RefundAfterLookup"].validation_mode == "IGNORE_ALL_FINDINGS"
    error_message = "Per-policy enforcement_mode and validation_mode should pass through"
  }

  assert {
    condition     = awscc_bedrockagentcore_policy.policy["orders_engine/AllowLookup"].enforcement_mode == "ACTIVE" && awscc_bedrockagentcore_policy.policy["orders_engine/AllowLookup"].validation_mode == "FAIL_ON_ANY_FINDINGS"
    error_message = "Policies should default to ACTIVE and FAIL_ON_ANY_FINDINGS"
  }

  assert {
    condition     = strcontains(awscc_bedrockagentcore_policy.policy["orders_engine/KeepsUnknownBraces"].definition.cedar.statement, "{{not-a-placeholder}}")
    error_message = "Text that is not a known placeholder must pass through unchanged"
  }

  assert {
    condition     = awscc_bedrockagentcore_policy.policy["orders_engine/AllowLookup"].policy_engine_id == awscc_bedrockagentcore_policy_engine.policy_engine["orders_engine"].policy_engine_id
    error_message = "Policies should reference the engine by policy_engine_id"
  }

  assert {
    condition     = awscc_bedrockagentcore_gateway.gateway["orders-gateway"].policy_engine_configuration.arn == awscc_bedrockagentcore_policy_engine.policy_engine["orders_engine"].policy_engine_arn && awscc_bedrockagentcore_gateway.gateway["orders-gateway"].policy_engine_configuration.mode == "LOG_ONLY"
    error_message = "The gateway should attach the module-managed engine by ARN in the requested mode"
  }

  assert {
    condition = alltrue([
      for sid in ["AllowPolicyEngineConfiguration", "AllowPolicyEngineAuthorization", "AllowPolicySessionWorkloadIdentity", "AllowLambdaInvocation"] :
      contains([for s in data.aws_iam_policy_document.gateway_policy["orders-gateway"].statement : s.sid], sid)
    ])
    error_message = "The gateway role should get the policy engine, temporal session and Lambda statements"
  }

  assert {
    condition = contains(flatten([
      for s in data.aws_iam_policy_document.gateway_policy["orders-gateway"].statement : tolist(s.resources) if s.sid == "AllowPolicyEngineAuthorization"
    ]), "arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/orders-gateway-*")
    error_message = "AuthorizeAction should be scoped to the gateway's own ARN pattern"
  }

  assert {
    condition = contains(flatten([
      for s in data.aws_iam_policy_document.gateway_policy["orders-gateway"].statement : tolist(s.resources) if s.sid == "AllowPolicyEngineConfiguration"
    ]), awscc_bedrockagentcore_policy_engine.policy_engine["orders_engine"].policy_engine_arn)
    error_message = "GetPolicyEngine should be scoped to the attached engine"
  }

  assert {
    condition     = length(keys(output.policy_ids)) == 3 && contains(keys(output.policy_arns), "orders_engine/RefundAfterLookup")
    error_message = "Policy outputs should be keyed <engine>/<policy>"
  }
}

run "policy_engine_by_arn_without_module_engine" {
  command = apply

  variables {
    gateways = {
      shared-gateway = {
        policy_engine_configuration = {
          policy_engine_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:policy-engine/shared_engine-0123456789"
        }
      }
    }
  }

  assert {
    condition     = awscc_bedrockagentcore_gateway.gateway["shared-gateway"].policy_engine_configuration.arn == "arn:aws:bedrock-agentcore:us-east-1:123456789012:policy-engine/shared_engine-0123456789" && awscc_bedrockagentcore_gateway.gateway["shared-gateway"].policy_engine_configuration.mode == "ENFORCE"
    error_message = "An existing engine given by ARN should be attached in ENFORCE mode by default"
  }

  assert {
    condition     = length(awscc_bedrockagentcore_policy_engine.policy_engine) == 0
    error_message = "No policy engine should be created when none is declared"
  }
}

# ─── Runtime attributes, JWT inbound auth and HTTP gateway targets ───

run "http_targets_and_runtime_attributes" {
  command = apply

  variables {
    runtimes = {
      support_agent = {
        source_type            = "CODE"
        code_source_path       = "examples/basic-code-runtime/src"
        code_entry_point       = ["agent.py"]
        protocol_configuration = "HTTP"
        platform_version       = "1.0"
        lifecycle_configuration = {
          idle_runtime_session_timeout = 600
          max_lifetime                 = 3600
        }
        request_header_allowlist = ["Authorization", "X-Correlation-Id"]
        authorizer_configuration = {
          custom_jwt_authorizer = {
            discovery_url   = "https://idp.example.com/.well-known/openid-configuration"
            allowed_clients = ["client-1"]
            custom_claims = [{
              inbound_token_claim_name       = "groups"
              inbound_token_claim_value_type = "STRING_ARRAY"
              claim_match_operator           = "CONTAINS_ANY"
              match_value_string_list        = ["admins", "agents"]
            }]
            allowed_workload_configuration = {
              workload_identities = ["agents-gateway-abcdefghij"]
            }
          }
        }
      }
    }

    gateways = {
      agents-gateway = {
        protocol_type   = "NONE"
        authorizer_type = "CUSTOM_JWT"
        authorizer_configuration = {
          custom_jwt_authorizer = {
            discovery_url  = "https://idp.example.com/.well-known/openid-configuration"
            allowed_scopes = ["agents/invoke"]
            custom_claims = [{
              inbound_token_claim_name = "token_use"
              match_value_string       = "access"
            }]
          }
        }
        policy_engine_configuration = {
          policy_engine_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:policy-engine/shared_engine-0123456789"
          mode              = "LOG_ONLY"
        }
        interceptor_configurations = [{
          interception_points = ["REQUEST"]
          interceptor = {
            lambda = {
              arn = "arn:aws:lambda:us-east-1:123456789012:function:interceptor"
            }
          }
        }]
      }
    }

    gateway_targets = {
      agent = {
        gateway_name = "agents-gateway"
        type         = "AGENTCORE_RUNTIME"
        agentcore_runtime_config = {
          runtime_name = "support_agent"
        }
        metadata_configuration = {
          allowed_request_headers  = ["x-correlation-id"]
          allowed_response_headers = ["x-request-id"]
        }
      }
      external = {
        gateway_name             = "agents-gateway"
        type                     = "AGENTCORE_RUNTIME"
        credential_provider_type = "CALLER_IAM_CREDENTIALS"
        caller_iam_config = {
          service = "bedrock-agentcore"
        }
        agentcore_runtime_config = {
          runtime_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/other_agent-0123456789"
          qualifier   = "prod"
          schema = {
            s3_uri = "s3://schemas/other_agent.yaml"
          }
        }
      }
      partner = {
        gateway_name             = "agents-gateway"
        type                     = "HTTP_PASSTHROUGH"
        credential_provider_type = "JWT_PASSTHROUGH"
        passthrough_config = {
          endpoint                                   = "https://partner.example.com"
          protocol_type                              = "A2A"
          static_query_parameters                    = { version = "v1" }
          static_query_parameter_conflict_resolution = "STATIC_OVERRIDE"
          stickiness_configuration = {
            identifier = "$context.header.x-session-id"
            timeout    = 600
          }
        }
      }
    }
  }

  # runtime
  assert {
    condition     = awscc_bedrockagentcore_runtime.runtime_code["support_agent"].protocol_configuration == "HTTP" && awscc_bedrockagentcore_runtime.runtime_code["support_agent"].platform_version == "1.0"
    error_message = "protocol_configuration and platform_version should pass through"
  }

  assert {
    condition     = awscc_bedrockagentcore_runtime.runtime_code["support_agent"].lifecycle_configuration.idle_runtime_session_timeout == 600 && awscc_bedrockagentcore_runtime.runtime_code["support_agent"].lifecycle_configuration.max_lifetime == 3600
    error_message = "lifecycle_configuration should pass through"
  }

  assert {
    condition     = contains(awscc_bedrockagentcore_runtime.runtime_code["support_agent"].request_header_configuration.request_header_allowlist, "Authorization")
    error_message = "request_header_allowlist should be sent as request_header_configuration"
  }

  assert {
    condition     = awscc_bedrockagentcore_runtime.runtime_code["support_agent"].authorizer_configuration.custom_jwt_authorizer.custom_claims[0].authorizing_claim_match_value.claim_match_operator == "CONTAINS_ANY" && contains(awscc_bedrockagentcore_runtime.runtime_code["support_agent"].authorizer_configuration.custom_jwt_authorizer.custom_claims[0].authorizing_claim_match_value.claim_match_value.match_value_string_list, "agents")
    error_message = "Custom claims should map to the awscc authorizing_claim_match_value shape"
  }

  assert {
    condition     = contains(awscc_bedrockagentcore_runtime.runtime_code["support_agent"].authorizer_configuration.custom_jwt_authorizer.allowed_workload_configuration.workload_identities, "agents-gateway-abcdefghij")
    error_message = "allowed_workload_configuration should pass through"
  }

  assert {
    condition = contains(flatten([
      for s in data.aws_iam_policy_document.runtime_policy["support_agent"].statement : tolist(s.resources) if s.sid == "AllowWorkloadAccessToken"
    ]), "arn:aws:bedrock-agentcore:us-east-1:123456789012:workload-identity-directory/default/workload-identity/support_agent-*")
    error_message = "The runtime role should get workload access tokens for its own identity"
  }

  # gateway without a protocol type: created with the aws provider resource
  assert {
    condition     = length(awscc_bedrockagentcore_gateway.gateway) == 0 && length(aws_bedrockagentcore_gateway.gateway_http) == 1
    error_message = "A protocol_type NONE gateway must be an aws_bedrockagentcore_gateway, not an awscc gateway"
  }

  assert {
    condition     = aws_bedrockagentcore_gateway.gateway_http["agents-gateway"].authorizer_configuration[0].custom_jwt_authorizer[0].discovery_url == "https://idp.example.com/.well-known/openid-configuration" && contains(aws_bedrockagentcore_gateway.gateway_http["agents-gateway"].authorizer_configuration[0].custom_jwt_authorizer[0].allowed_scopes, "agents/invoke")
    error_message = "The JWT authorizer should render as blocks on the aws gateway resource"
  }

  assert {
    condition     = [for c in aws_bedrockagentcore_gateway.gateway_http["agents-gateway"].authorizer_configuration[0].custom_jwt_authorizer[0].custom_claim : c.authorizing_claim_match_value[0].claim_match_value[0].match_value_string][0] == "access"
    error_message = "Custom claims should render as custom_claim blocks on the aws gateway resource"
  }

  assert {
    condition     = aws_bedrockagentcore_gateway.gateway_http["agents-gateway"].policy_engine_configuration[0].arn == "arn:aws:bedrock-agentcore:us-east-1:123456789012:policy-engine/shared_engine-0123456789" && aws_bedrockagentcore_gateway.gateway_http["agents-gateway"].policy_engine_configuration[0].mode == "LOG_ONLY"
    error_message = "Policy engines attach to NONE gateways through the policy_engine_configuration block"
  }

  assert {
    condition     = aws_bedrockagentcore_gateway.gateway_http["agents-gateway"].interceptor_configuration[0].input_configuration[0].pass_request_headers == false
    error_message = "Interceptors on NONE gateways should default pass_request_headers to false"
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_target.gateway_target["agent"].gateway_identifier == aws_bedrockagentcore_gateway.gateway_http["agents-gateway"].gateway_id && output.gateway_arns["agents-gateway"] == aws_bedrockagentcore_gateway.gateway_http["agents-gateway"].gateway_arn
    error_message = "Targets and outputs should resolve NONE gateways through the merged gateway maps"
  }

  # runtime target by name
  assert {
    condition     = aws_bedrockagentcore_gateway_target.gateway_target["agent"].target_configuration[0].http[0].agentcore_runtime[0].arn == awscc_bedrockagentcore_runtime.runtime_code["support_agent"].agent_runtime_arn
    error_message = "runtime_name should resolve to the module-managed runtime ARN"
  }

  assert {
    condition     = length(aws_bedrockagentcore_gateway_target.gateway_target["agent"].credential_provider_configuration[0].gateway_iam_role) == 1 && aws_bedrockagentcore_gateway_target.gateway_target["agent"].credential_provider_configuration[0].gateway_iam_role[0].service == null
    error_message = "A runtime target without a credential type must render an empty gateway_iam_role block (no SigV4 service)"
  }

  assert {
    condition     = contains(aws_bedrockagentcore_gateway_target.gateway_target["agent"].metadata_configuration[0].allowed_request_headers, "x-correlation-id") && contains(aws_bedrockagentcore_gateway_target.gateway_target["agent"].metadata_configuration[0].allowed_response_headers, "x-request-id")
    error_message = "metadata_configuration should pass through"
  }

  assert {
    condition     = length(aws_bedrockagentcore_gateway_target.gateway_target["agent"].target_configuration[0].mcp) == 0
    error_message = "HTTP targets must not render an mcp block"
  }

  # runtime target by ARN with caller credentials and an S3 schema
  assert {
    condition     = aws_bedrockagentcore_gateway_target.gateway_target["external"].target_configuration[0].http[0].agentcore_runtime[0].arn == "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/other_agent-0123456789" && aws_bedrockagentcore_gateway_target.gateway_target["external"].target_configuration[0].http[0].agentcore_runtime[0].qualifier == "prod"
    error_message = "runtime_arn and qualifier should pass through"
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_target.gateway_target["external"].target_configuration[0].http[0].agentcore_runtime[0].schema[0].source[0].s3[0].uri == "s3://schemas/other_agent.yaml"
    error_message = "An S3 schema should render under schema.source.s3"
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_target.gateway_target["external"].credential_provider_configuration[0].caller_iam_credentials[0].service == "bedrock-agentcore"
    error_message = "CALLER_IAM_CREDENTIALS should render caller_iam_credentials"
  }

  # passthrough target
  assert {
    condition     = length(aws_bedrockagentcore_gateway_target.gateway_target["partner"].credential_provider_configuration[0].jwt_passthrough) == 1
    error_message = "JWT_PASSTHROUGH should render an empty jwt_passthrough block"
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_target.gateway_target["partner"].target_configuration[0].http[0].passthrough[0].protocol_type == "A2A" && aws_bedrockagentcore_gateway_target.gateway_target["partner"].target_configuration[0].http[0].passthrough[0].static_query_parameters["version"] == "v1" && aws_bedrockagentcore_gateway_target.gateway_target["partner"].target_configuration[0].http[0].passthrough[0].static_query_parameter_conflict_resolution == "STATIC_OVERRIDE"
    error_message = "passthrough_config should pass through"
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_target.gateway_target["partner"].target_configuration[0].http[0].passthrough[0].stickiness_configuration[0].timeout == 600
    error_message = "stickiness_configuration should pass through"
  }

  # gateway role IAM for runtime targets
  assert {
    condition = alltrue([
      for arn in [
        "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/support_agent-*",
        "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/other_agent-0123456789",
        "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/other_agent-0123456789/runtime-endpoint/*"
      ] :
      contains(flatten([for s in data.aws_iam_policy_document.gateway_policy["agents-gateway"].statement : tolist(s.resources) if s.sid == "AllowAgentRuntimeInvocation"]), arn)
    ])
    error_message = "The gateway role should be allowed to invoke both runtime targets (name pattern and literal ARN with endpoints)"
  }

  assert {
    condition     = length(keys(output.runtime_workload_identity_arns)) == 1 && length(keys(output.gateway_workload_identity_arns)) == 1
    error_message = "Runtime and gateway workload identity outputs should be populated"
  }
}

# ─── MCP gateway: session, streaming, interceptor payload filter, static-schema MCP server target ───

run "mcp_gateway_and_server_target" {
  command = apply

  variables {
    gateways = {
      tools-gateway = {
        authorizer_type = "CUSTOM_JWT"
        authorizer_configuration = {
          custom_jwt_authorizer = {
            discovery_url            = "https://idp.example.com/.well-known/openid-configuration"
            allowed_scopes           = ["tools/read"]
            advertised_scope_mapping = { "tools/read" = "read" }
          }
        }
        waf_configuration = {
          failure_mode = "FAIL_OPEN"
          web_acl_arn  = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/tools/00000000-0000-0000-0000-000000000000"
        }
        protocol_configuration = {
          mcp = {
            supported_versions         = ["2025-11-25"]
            session_timeout_in_seconds = 1800
            enable_response_streaming  = true
          }
        }
        interceptor_configurations = [{
          interception_points = ["REQUEST", "RESPONSE"]
          interceptor = {
            lambda = {
              arn = "arn:aws:lambda:us-east-1:123456789012:function:interceptor"
            }
          }
          input_configuration = {
            pass_request_headers = false
            exclude_fields       = ["RESPONSE_BODY"]
          }
        }]
      }
    }

    gateway_targets = {
      weather = {
        gateway_name = "tools-gateway"
        type         = "MCP_SERVER"
        mcp_server_config = {
          endpoint          = "https://mcp.example.com/mcp"
          listing_mode      = "DYNAMIC"
          resource_priority = 50
          tool_schema = {
            inline_payload = jsonencode({
              tools = [{
                name        = "get_weather"
                description = "Weather for a location"
                inputSchema = { type = "object" }
              }]
            })
          }
        }
      }
    }
  }

  assert {
    condition     = awscc_bedrockagentcore_gateway.gateway["tools-gateway"].protocol_configuration.mcp.session_configuration.session_timeout_in_seconds == 1800 && awscc_bedrockagentcore_gateway.gateway["tools-gateway"].protocol_configuration.mcp.streaming_configuration.enable_response_streaming == true
    error_message = "MCP session timeout and streaming should render under protocol_configuration.mcp"
  }

  assert {
    condition     = awscc_bedrockagentcore_gateway.gateway["tools-gateway"].interceptor_configurations[0].input_configuration.payload_filter.exclude[0].field == "RESPONSE_BODY"
    error_message = "exclude_fields should render as a payload_filter"
  }

  assert {
    condition     = awscc_bedrockagentcore_gateway.gateway["tools-gateway"].authorizer_configuration.custom_jwt_authorizer.advertised_scope_mapping["tools/read"] == "read"
    error_message = "advertised_scope_mapping should pass through on MCP gateways"
  }

  assert {
    condition     = awscc_bedrockagentcore_gateway.gateway["tools-gateway"].waf_configuration.failure_mode == "FAIL_OPEN"
    error_message = "waf_configuration.failure_mode should pass through"
  }

  assert {
    condition     = aws_wafv2_web_acl_association.gateway["tools-gateway"].resource_arn == awscc_bedrockagentcore_gateway.gateway["tools-gateway"].gateway_arn && endswith(aws_wafv2_web_acl_association.gateway["tools-gateway"].web_acl_arn, "/00000000-0000-0000-0000-000000000000")
    error_message = "web_acl_arn should be associated with the gateway ARN"
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_target.gateway_target["weather"].target_configuration[0].mcp[0].mcp_server[0].listing_mode == "DYNAMIC" && aws_bedrockagentcore_gateway_target.gateway_target["weather"].target_configuration[0].mcp[0].mcp_server[0].resource_priority == 50
    error_message = "listing_mode and resource_priority should pass through"
  }

  assert {
    condition     = jsondecode(aws_bedrockagentcore_gateway_target.gateway_target["weather"].target_configuration[0].mcp[0].mcp_server[0].mcp_tool_schema[0].inline_payload[0].payload).tools[0].name == "get_weather"
    error_message = "The static tool schema should be sent as mcp_tool_schema.inline_payload"
  }

  assert {
    condition     = length(aws_bedrockagentcore_gateway_target.gateway_target["weather"].credential_provider_configuration) == 0 && length(aws_bedrockagentcore_gateway_target.gateway_target["weather"].target_configuration[0].http) == 0
    error_message = "An MCP server target without credentials must not render credential or http blocks"
  }
}

# ─── Configuration bundles, workload identities and the runtime role ───

run "bundles_and_workload_identities" {
  command = apply

  variables {
    runtimes = {
      my_agent = {
        source_type      = "CODE"
        code_source_path = "examples/basic-code-runtime/src"
        code_entry_point = ["agent.py"]
      }
    }

    configuration_bundles = {
      my_agent_config = {
        description    = "Prompt and model"
        commit_message = "initial"
        components = {
          "{{runtime:my_agent}}" = {
            system_prompt = "Be brief."
            temperature   = 0.2
          }
          "arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/other-gateway-abcdefghij" = {
            instructions = "unchanged literal key"
          }
        }
      }
    }

    workload_identities = {
      external-agent = {
        allowed_resource_oauth2_return_urls = ["https://agent.example.com/oauth2/callback"]
      }
    }
  }

  assert {
    condition     = jsondecode(awscc_bedrockagentcore_configuration_bundle.bundle["my_agent_config"].components[awscc_bedrockagentcore_runtime.runtime_code["my_agent"].agent_runtime_arn].configuration).system_prompt == "Be brief."
    error_message = "{{runtime:my_agent}} should resolve to the runtime ARN and the configuration should be stored as JSON"
  }

  assert {
    condition     = contains(keys(awscc_bedrockagentcore_configuration_bundle.bundle["my_agent_config"].components), "arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/other-gateway-abcdefghij")
    error_message = "Literal component keys must be kept as given"
  }

  assert {
    condition     = contains([for s in data.aws_iam_policy_document.runtime_policy["my_agent"].statement : s.sid], "AllowConfigurationBundleRead")
    error_message = "The runtime role should be able to read bundles when the module call defines any"
  }

  assert {
    condition     = contains(aws_bedrockagentcore_workload_identity.workload_identity["external-agent"].allowed_resource_oauth2_return_urls, "https://agent.example.com/oauth2/callback")
    error_message = "allowed_resource_oauth2_return_urls should pass through"
  }

  assert {
    condition     = contains(keys(output.workload_identity_arns), "external-agent") && contains(keys(output.configuration_bundle_version_ids), "my_agent_config")
    error_message = "Workload identity and bundle outputs should be populated"
  }
}

run "runtime_without_bundles_has_no_bundle_statement" {
  command = apply

  variables {
    runtimes = {
      my_agent = {
        source_type      = "CODE"
        code_source_path = "examples/basic-code-runtime/src"
        code_entry_point = ["agent.py"]
      }
    }
  }

  assert {
    condition     = !contains([for s in data.aws_iam_policy_document.runtime_policy["my_agent"].statement : s.sid], "AllowConfigurationBundleRead")
    error_message = "Without bundles the runtime role must not get the bundle statement"
  }

  # Mocked state fills computed attributes with generated values, so "unset stays null"
  # cannot be asserted here; the mocked example runs cover that path instead.
  assert {
    condition     = contains([for st in data.aws_iam_policy_document.runtime_policy["my_agent"].statement : st.sid], "AllowWorkloadAccessToken")
    error_message = "The runtime role should always get the workload access token statement"
  }
}

# ─── Agent Registry: records, descriptors and publisher IAM ───

run "registry_records_and_publisher_role" {
  command = apply

  variables {
    registries = {
      team = {
        auto_approve_records = true
        publisher = {
          allow_approval         = true
          trusted_principal_arns = ["arn:aws:iam::123456789012:role/release-pipeline"]
          trusted_services       = ["codebuild.amazonaws.com"]
        }
        records = {
          weather = {
            record_type                    = "MCP"
            descriptor_data                = jsonencode({ name = "io.example/weather", description = "Weather", version = "1.0.0" })
            descriptor_data_schema_version = "2025-12-11"
            tools_data                     = jsonencode({ tools = [] })
            tools_data_schema_version      = "2025-11-25"
          }
          card = {
            record_type           = "AGENT"
            descriptor_source_url = "https://agent.example.com/.well-known/agent-card.json"
          }
          note = {
            record_type     = "CUSTOM"
            descriptor_data = jsonencode({ hello = "world" })
          }
        }
      }
    }
  }

  assert {
    condition     = length(awscc_agentregistry_registry.registry["team"].approval_configuration.auto_approval_rules) == 1 && contains(awscc_agentregistry_registry.registry["team"].approval_configuration.auto_approval_rules, "APPROVE_ALL")
    error_message = "auto_approve_records should map to the APPROVE_ALL rule"
  }

  assert {
    condition     = jsondecode(awscc_agentregistry_registry_record.record["team/weather"].descriptors.mcp_server.data).name == "io.example/weather" && awscc_agentregistry_registry_record.record["team/weather"].descriptors.mcp_server.additional_data.tools.data_schema_version == "2025-11-25"
    error_message = "MCP records should carry the server document and the tools document"
  }

  assert {
    condition     = awscc_agentregistry_registry_record.record["team/card"].descriptors.a2_a_agent_card.source.from_url.url == "https://agent.example.com/.well-known/agent-card.json"
    error_message = "AGENT records default to an A2A agent card descriptor and may be synchronized from a URL"
  }

  assert {
    condition     = jsondecode(awscc_agentregistry_registry_record.record["team/note"].descriptors.custom.data).hello == "world"
    error_message = "CUSTOM records should use the custom descriptor"
  }

  assert {
    condition     = awscc_agentregistry_registry_record.record["team/note"].registry_id == awscc_agentregistry_registry.registry["team"].registry_id
    error_message = "Records should reference their registry by ID"
  }

  assert {
    condition     = contains([for s in data.aws_iam_policy_document.registry_publisher_policy["team"].statement : s.sid], "AllowRegistryRecordApproval")
    error_message = "allow_approval should add UpdateRegistryRecordStatus"
  }

  assert {
    condition     = length(data.aws_iam_policy_document.registry_publisher_assume_role["team"].statement) == 2
    error_message = "Trusted principals and trusted services should each get an assume-role statement"
  }

  assert {
    condition     = contains(keys(output.registry_publisher_role_arns), "team") && contains(keys(output.registry_record_ids), "team/weather")
    error_message = "Publisher role and record outputs should be populated"
  }
}

run "registry_without_publisher_role" {
  command = apply

  variables {
    registries = {
      catalog = {
        description = "Manual approval, policy only"
      }
    }
  }

  assert {
    condition     = length(awscc_agentregistry_registry.registry["catalog"].approval_configuration.auto_approval_rules) == 0
    error_message = "Manual approval should send an empty rule list"
  }

  assert {
    condition     = length(aws_iam_policy.registry_publisher) == 1 && length(aws_iam_role.registry_publisher) == 0
    error_message = "A publisher policy is created by default, a role only with trusted principals or services"
  }

  assert {
    condition     = !contains([for s in data.aws_iam_policy_document.registry_publisher_policy["catalog"].statement : s.sid], "AllowRegistryRecordApproval")
    error_message = "Approval permission must be opt-in"
  }
}

run "registry_without_publisher_policy" {
  command = apply

  variables {
    registries = {
      catalog = {
        publisher = {
          create_policy = false
        }
      }
    }
  }

  assert {
    condition     = length(aws_iam_policy.registry_publisher) == 0 && length(aws_iam_role.registry_publisher) == 0
    error_message = "create_policy = false must create no publisher IAM"
  }
}
