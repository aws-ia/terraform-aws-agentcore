# Validation unit tests: each run feeds the module one invalid input and expects the
# matching variable validation to reject it (expect_failures). Mocked providers,
# plan only, no AWS credentials needed.
#
#   terraform test -filter=tests/00_unit_validations.tftest.hcl


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

run "runtime_rejects_unknown_protocol" {
  command = plan

  variables {
    runtimes = { a = { source_type = "CONTAINER", container_image_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/agent:latest", execution_role_arn = "arn:aws:iam::123456789012:role/agent", protocol_configuration = "GRPC" } }
  }

  expect_failures = [var.runtimes]
}

run "runtime_rejects_lifecycle_below_minimum" {
  command = plan

  variables {
    runtimes = { a = { source_type = "CONTAINER", container_image_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/agent:latest", execution_role_arn = "arn:aws:iam::123456789012:role/agent", lifecycle_configuration = { idle_runtime_session_timeout = 30 } } }
  }

  expect_failures = [var.runtimes]
}

run "runtime_rejects_idle_above_max_lifetime" {
  command = plan

  variables {
    runtimes = { a = { source_type = "CONTAINER", container_image_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/agent:latest", execution_role_arn = "arn:aws:iam::123456789012:role/agent", lifecycle_configuration = { idle_runtime_session_timeout = 3600, max_lifetime = 600 } } }
  }

  expect_failures = [var.runtimes]
}

run "runtime_rejects_more_than_20_headers" {
  command = plan

  variables {
    runtimes = { a = { source_type = "CONTAINER", container_image_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/agent:latest", execution_role_arn = "arn:aws:iam::123456789012:role/agent", request_header_allowlist = [for i in range(21) : "X-Header-${i}"] } }
  }

  expect_failures = [var.runtimes]
}

run "runtime_rejects_reserved_amzn_header" {
  command = plan

  variables {
    runtimes = { a = { source_type = "CONTAINER", container_image_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/agent:latest", execution_role_arn = "arn:aws:iam::123456789012:role/agent", request_header_allowlist = ["X-Amzn-Trace-Id"] } }
  }

  expect_failures = [var.runtimes]
}

run "runtime_accepts_custom_amzn_header_prefix_but_rejects_bad_claim" {
  command = plan

  variables {
    runtimes = { a = { source_type = "CONTAINER", container_image_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/agent:latest", execution_role_arn = "arn:aws:iam::123456789012:role/agent", request_header_allowlist = ["X-Amzn-Bedrock-AgentCore-Runtime-Custom-UserId"], authorizer_configuration = { custom_jwt_authorizer = { discovery_url = "https://idp.example.com/.well-known/openid-configuration", allowed_clients = ["c1"], custom_claims = [{ inbound_token_claim_name = "role", claim_match_operator = "CONTAINS", match_value_string = "x" }] } } } }
  }

  expect_failures = [var.runtimes]
}

run "runtime_rejects_jwt_without_constraints" {
  command = plan

  variables {
    runtimes = { a = { source_type = "CONTAINER", container_image_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/agent:latest", execution_role_arn = "arn:aws:iam::123456789012:role/agent", authorizer_configuration = { custom_jwt_authorizer = { discovery_url = "https://idp.example.com/.well-known/openid-configuration" } } } }
  }

  expect_failures = [var.runtimes]
}

run "runtime_rejects_string_array_claim_with_equals" {
  command = plan

  variables {
    runtimes = { a = { source_type = "CONTAINER", container_image_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/agent:latest", execution_role_arn = "arn:aws:iam::123456789012:role/agent", authorizer_configuration = { custom_jwt_authorizer = { discovery_url = "https://idp.example.com/.well-known/openid-configuration", allowed_clients = ["c1"], custom_claims = [{ inbound_token_claim_name = "groups", inbound_token_claim_value_type = "STRING_ARRAY", claim_match_operator = "EQUALS", match_value_string_list = ["a"] }] } } } }
  }

  expect_failures = [var.runtimes]
}

run "gateway_rejects_unknown_protocol_type" {
  command = plan

  variables {
    gateways = { g = { protocol_type = "HTTP" } }
  }

  expect_failures = [var.gateways]
}

run "gateway_rejects_protocol_configuration_on_none" {
  command = plan

  variables {
    gateways = { g = { protocol_type = "NONE", protocol_configuration = { mcp = { instructions = "x" } } } }
  }

  expect_failures = [var.gateways]
}

run "gateway_rejects_waf_on_none_gateway" {
  command = plan

  variables {
    gateways = { g = { protocol_type = "NONE", waf_configuration = { failure_mode = "FAIL_OPEN" } } }
  }

  expect_failures = [var.gateways]
}

run "gateway_rejects_exclude_fields_on_none_gateway" {
  command = plan

  variables {
    gateways = { g = { protocol_type = "NONE", interceptor_configurations = [{ interception_points = ["REQUEST"], interceptor = { lambda = { arn = "arn:aws:lambda:us-east-1:123456789012:function:i" } }, input_configuration = { exclude_fields = ["RESPONSE_BODY"] } }] } }
  }

  expect_failures = [var.gateways]
}

run "gateway_rejects_jwt_type_without_configuration" {
  command = plan

  variables {
    gateways = { g = { authorizer_type = "CUSTOM_JWT" } }
  }

  expect_failures = [var.gateways]
}

run "gateway_rejects_jwt_without_constraints" {
  command = plan

  variables {
    gateways = { g = { authorizer_type = "CUSTOM_JWT", authorizer_configuration = { custom_jwt_authorizer = { discovery_url = "https://idp.example.com/.well-known/openid-configuration" } } } }
  }

  expect_failures = [var.gateways]
}

run "gateway_rejects_advertised_scope_not_allowed" {
  command = plan

  variables {
    gateways = { g = { authorizer_type = "CUSTOM_JWT", authorizer_configuration = { custom_jwt_authorizer = { discovery_url = "https://idp.example.com/.well-known/openid-configuration", allowed_clients = ["c1"], allowed_scopes = ["read"], advertised_scope_mapping = { write = "w" } } } } }
  }

  expect_failures = [var.gateways]
}

run "gateway_rejects_session_timeout_out_of_range" {
  command = plan

  variables {
    gateways = { g = { protocol_configuration = { mcp = { session_timeout_in_seconds = 100 } } } }
  }

  expect_failures = [var.gateways]
}

run "gateway_rejects_unknown_waf_failure_mode" {
  command = plan

  variables {
    gateways = { g = { waf_configuration = { failure_mode = "OPEN" } } }
  }

  expect_failures = [var.gateways]
}

run "gateway_rejects_unknown_policy_engine_name" {
  command = plan

  variables {
    gateways = { g = { policy_engine_configuration = { policy_engine_name = "missing" } } }
  }

  expect_failures = [var.gateways]
}

run "gateway_rejects_policy_engine_name_and_arn" {
  command = plan

  variables {
    policy_engines = { e = {} }
    gateways       = { g = { policy_engine_configuration = { policy_engine_name = "e", policy_engine_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:policy-engine/e-0123456789" } } }
  }

  expect_failures = [var.gateways]
}

run "gateway_rejects_unknown_policy_engine_mode" {
  command = plan

  variables {
    policy_engines = { e = {} }
    gateways       = { g = { policy_engine_configuration = { policy_engine_name = "e", mode = "AUDIT" } } }
  }

  expect_failures = [var.gateways]
}

run "target_rejects_unknown_type" {
  command = plan

  variables {
    gateways        = { g = {} }
    gateway_targets = { t = { gateway_name = "g", type = "SMITHY" } }
  }

  expect_failures = [var.gateway_targets]
}

run "target_rejects_unknown_gateway" {
  command = plan

  variables {
    gateways        = { g = {} }
    gateway_targets = { t = { gateway_name = "other", type = "LAMBDA", credential_provider_type = "GATEWAY_IAM_ROLE", lambda_config = { lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:f", tool_schema_type = "INLINE", inline_schema = { name = "t", input_schema = { type = "object", properties = [{ name = "a", type = "string", required = true }] } } } } }
  }

  expect_failures = [var.gateway_targets]
}

run "target_rejects_lambda_on_none_gateway" {
  command = plan

  variables {
    gateways        = { g = { protocol_type = "NONE" } }
    gateway_targets = { t = { gateway_name = "g", type = "LAMBDA", credential_provider_type = "GATEWAY_IAM_ROLE", lambda_config = { lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:f", tool_schema_type = "INLINE", inline_schema = { name = "t", input_schema = { type = "object", properties = [{ name = "a", type = "string", required = true }] } } } } }
  }

  expect_failures = [var.gateway_targets]
}

run "target_rejects_runtime_target_on_mcp_gateway" {
  command = plan

  variables {
    gateways        = { g = {} }
    gateway_targets = { t = { gateway_name = "g", type = "AGENTCORE_RUNTIME", agentcore_runtime_config = { runtime_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/a-0123456789" } } }
  }

  expect_failures = [var.gateway_targets]
}

run "target_rejects_missing_type_configuration" {
  command = plan

  variables {
    gateways        = { g = { protocol_type = "NONE" } }
    gateway_targets = { t = { gateway_name = "g", type = "HTTP_PASSTHROUGH" } }
  }

  expect_failures = [var.gateway_targets]
}

run "target_rejects_runtime_name_and_arn" {
  command = plan

  variables {
    gateways        = { g = { protocol_type = "NONE" } }
    gateway_targets = { t = { gateway_name = "g", type = "AGENTCORE_RUNTIME", agentcore_runtime_config = { runtime_name = "a", runtime_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/a-0123456789" } } }
  }

  expect_failures = [var.gateway_targets]
}

run "target_rejects_unknown_runtime_name" {
  command = plan

  variables {
    gateways        = { g = { protocol_type = "NONE" } }
    gateway_targets = { t = { gateway_name = "g", type = "AGENTCORE_RUNTIME", agentcore_runtime_config = { runtime_name = "missing" } } }
  }

  expect_failures = [var.gateway_targets]
}

run "target_rejects_http_passthrough_endpoint" {
  command = plan

  variables {
    gateways        = { g = { protocol_type = "NONE" } }
    gateway_targets = { t = { gateway_name = "g", type = "HTTP_PASSTHROUGH", passthrough_config = { endpoint = "http://insecure.example.com", protocol_type = "A2A" } } }
  }

  expect_failures = [var.gateway_targets]
}

run "target_rejects_unknown_passthrough_protocol" {
  command = plan

  variables {
    gateways        = { g = { protocol_type = "NONE" } }
    gateway_targets = { t = { gateway_name = "g", type = "HTTP_PASSTHROUGH", passthrough_config = { endpoint = "https://x.example.com", protocol_type = "HTTP" } } }
  }

  expect_failures = [var.gateway_targets]
}

run "target_rejects_stickiness_timeout_out_of_range" {
  command = plan

  variables {
    gateways        = { g = { protocol_type = "NONE" } }
    gateway_targets = { t = { gateway_name = "g", type = "HTTP_PASSTHROUGH", passthrough_config = { endpoint = "https://x.example.com", protocol_type = "A2A", stickiness_configuration = { identifier = "$context.header.x", timeout = 0 } } } }
  }

  expect_failures = [var.gateway_targets]
}

run "target_rejects_unknown_listing_mode" {
  command = plan

  variables {
    gateways        = { g = {} }
    gateway_targets = { t = { gateway_name = "g", type = "MCP_SERVER", mcp_server_config = { endpoint = "https://mcp.example.com/mcp", listing_mode = "STATIC" } } }
  }

  expect_failures = [var.gateway_targets]
}

run "target_rejects_resource_priority_out_of_range" {
  command = plan

  variables {
    gateways        = { g = {} }
    gateway_targets = { t = { gateway_name = "g", type = "MCP_SERVER", mcp_server_config = { endpoint = "https://mcp.example.com/mcp", resource_priority = 5000 } } }
  }

  expect_failures = [var.gateway_targets]
}

run "target_rejects_tool_schema_with_two_sources" {
  command = plan

  variables {
    gateways        = { g = {} }
    gateway_targets = { t = { gateway_name = "g", type = "MCP_SERVER", mcp_server_config = { endpoint = "https://mcp.example.com/mcp", tool_schema = { inline_payload = "{}", s3_uri = "s3://b/k" } } } }
  }

  expect_failures = [var.gateway_targets]
}

run "target_rejects_more_than_10_headers" {
  command = plan

  variables {
    gateways        = { g = {} }
    gateway_targets = { t = { gateway_name = "g", type = "LAMBDA", credential_provider_type = "GATEWAY_IAM_ROLE", lambda_config = { lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:f", tool_schema_type = "INLINE", inline_schema = { name = "t", input_schema = { type = "object", properties = [{ name = "a", type = "string", required = true }] } } }, metadata_configuration = { allowed_request_headers = [for i in range(11) : "x-h-${i}"] } } }
  }

  expect_failures = [var.gateway_targets]
}

run "target_rejects_caller_credentials_without_config" {
  command = plan

  variables {
    gateways        = { g = { protocol_type = "NONE" } }
    gateway_targets = { t = { gateway_name = "g", type = "AGENTCORE_RUNTIME", credential_provider_type = "CALLER_IAM_CREDENTIALS", agentcore_runtime_config = { runtime_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/a-0123456789" } } }
  }

  expect_failures = [var.gateway_targets]
}

run "target_rejects_unknown_credential_type" {
  command = plan

  variables {
    gateways        = { g = {} }
    gateway_targets = { t = { gateway_name = "g", type = "LAMBDA", credential_provider_type = "BASIC", lambda_config = { lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:f", tool_schema_type = "INLINE", inline_schema = { name = "t", input_schema = { type = "object", properties = [{ name = "a", type = "string", required = true }] } } } } }
  }

  expect_failures = [var.gateway_targets]
}

run "policy_engine_rejects_hyphenated_name" {
  command = plan

  variables {
    policy_engines = { "my-engine" = {} }
  }

  expect_failures = [var.policy_engines]
}

run "policy_engine_rejects_duplicate_policy_names" {
  command = plan

  variables {
    policy_engines = { e = { policies = [{ name = "P", statement = "permit(principal, action, resource is AgentCore::Gateway);" }, { name = "P", statement = "forbid(principal, action, resource is AgentCore::Gateway);" }] } }
  }

  expect_failures = [var.policy_engines]
}

run "policy_engine_rejects_unknown_language" {
  command = plan

  variables {
    policy_engines = { e = { policies = [{ name = "P", language = "REGO", statement = "allow = true" }] } }
  }

  expect_failures = [var.policy_engines]
}

run "policy_engine_rejects_enforce_as_policy_mode" {
  command = plan

  variables {
    policy_engines = { e = { policies = [{ name = "P", enforcement_mode = "ENFORCE", statement = "permit(principal, action, resource is AgentCore::Gateway);" }] } }
  }

  expect_failures = [var.policy_engines]
}

run "policy_engine_rejects_unknown_validation_mode" {
  command = plan

  variables {
    policy_engines = { e = { policies = [{ name = "P", validation_mode = "NONE", statement = "permit(principal, action, resource is AgentCore::Gateway);" }] } }
  }

  expect_failures = [var.policy_engines]
}

run "bundle_rejects_hyphenated_name" {
  command = plan

  variables {
    configuration_bundles = { "my-bundle" = { components = { "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/a-0123456789" = { k = "v" } } } }
  }

  expect_failures = [var.configuration_bundles]
}

run "bundle_rejects_empty_components" {
  command = plan

  variables {
    configuration_bundles = { my_bundle = { components = {} } }
  }

  expect_failures = [var.configuration_bundles]
}

run "workload_identity_rejects_bad_name" {
  command = plan

  variables {
    workload_identities = { "bad name" = {} }
  }

  expect_failures = [var.workload_identities]
}

run "registry_rejects_unknown_authorizer_type" {
  command = plan

  variables {
    registries = { r = { authorizer_type = "OAUTH" } }
  }

  expect_failures = [var.registries]
}

run "registry_rejects_jwt_without_configuration" {
  command = plan

  variables {
    registries = { r = { authorizer_type = "CUSTOM_JWT" } }
  }

  expect_failures = [var.registries]
}

run "registry_rejects_unknown_auto_detection_scope" {
  command = plan

  variables {
    registries = { r = { auto_detection = { scope = "ACCOUNT" } } }
  }

  expect_failures = [var.registries]
}

run "registry_rejects_unknown_record_type" {
  command = plan

  variables {
    registries = { r = { records = { x = { record_type = "TOOL", descriptor_data = "{}" } } } }
  }

  expect_failures = [var.registries]
}

run "registry_rejects_record_without_data_or_url" {
  command = plan

  variables {
    registries = { r = { records = { x = { record_type = "CUSTOM" } } } }
  }

  expect_failures = [var.registries]
}

run "registry_rejects_bad_record_name" {
  command = plan

  variables {
    registries = { r = { records = { "bad name" = { record_type = "CUSTOM", descriptor_data = "{}" } } } }
  }

  expect_failures = [var.registries]
}
