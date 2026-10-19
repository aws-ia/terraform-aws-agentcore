# Provider-mocked unit tests: every example is planned and applied against mock
# providers, so no AWS credentials or resources are needed and the run takes
# seconds. Mock defaults only cover attributes that providers validate on the
# client side (ARN and ID formats); everything else is generated.
#
#   terraform test -filter=tests/00_unit_mocked.tftest.hcl

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

# ─── Existing examples ───

run "mock_basic_code_runtime" {
  command = apply
  module {
    source = "./examples/basic-code-runtime"
  }
  providers = {
    aws   = aws
    awscc = awscc
    time  = time
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.runtime_ids)) == 1
    error_message = "Should plan exactly 1 runtime"
  }
}

run "mock_basic_container_runtime" {
  command = apply
  module {
    source = "./examples/basic-container-runtime"
  }
  providers = {
    aws   = aws
    awscc = awscc
    time  = time
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.ecr_repository_urls)) == 1
    error_message = "Should plan exactly 1 ECR repository"
  }
}

run "mock_complete" {
  command = apply
  module {
    source = "./examples/complete"
  }
  providers = {
    aws   = aws
    awscc = awscc
    time  = time
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.runtime_ids)) == 2
    error_message = "Should plan exactly 2 runtimes"
  }
}

# ─── Agent Registry ───

run "mock_agent_registry" {
  command = apply
  module {
    source = "./examples/agent-registry"
  }
  providers = {
    aws   = aws
    awscc = awscc
    time  = time
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.registry_ids)) == 1
    error_message = "Should plan exactly 1 registry"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.registry_publisher_role_arns)) == 1
    error_message = "Should plan the publisher role"
  }

  assert {
    condition     = contains(keys(module.terraform-aws-agentcore.registry_record_ids), "team-agent-registry/weather-mcp-server")
    error_message = "Should plan the weather-mcp-server record"
  }
}

# ─── Gateway + Policy ───

run "mock_gateway_policy" {
  command = apply
  module {
    source = "./examples/gateway-policy"
  }
  providers = {
    aws   = aws
    awscc = awscc
    time  = time
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.policy_ids)) == 3
    error_message = "Should plan exactly 3 policies"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.gateway_target_ids)) == 2
    error_message = "Should plan exactly 2 gateway targets"
  }
}

# ─── Configuration bundles ───

run "mock_configuration_bundles" {
  command = apply
  module {
    source = "./examples/configuration-bundles"
  }
  providers = {
    aws   = aws
    awscc = awscc
    time  = time
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.configuration_bundle_ids)) == 2
    error_message = "Should plan exactly 2 configuration bundles"
  }
}

# ─── Gateway targets (JWT, MCP server schema, runtime and passthrough targets) ───

run "mock_gateway_targets" {
  command = apply
  module {
    source = "./examples/gateway-targets"
  }
  providers = {
    aws   = aws
    awscc = awscc
    time  = time
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.gateway_ids)) == 2
    error_message = "Should plan exactly 2 gateways"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.gateway_target_ids)) == 3
    error_message = "Should plan exactly 3 gateway targets"
  }
}

# ─── Workload identity ───

run "mock_workload_identity" {
  command = apply
  module {
    source = "./examples/workload-identity"
  }
  providers = {
    aws   = aws
    awscc = awscc
    time  = time
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.workload_identity_arns)) == 1
    error_message = "Should plan exactly 1 workload identity"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.runtime_workload_identity_arns)) == 1
    error_message = "Should expose the runtime's workload identity"
  }
}
