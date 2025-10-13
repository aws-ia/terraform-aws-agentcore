<!-- BEGIN_TF_DOCS -->
# Bedrock AgentCore Module

The [Amazon Bedrock AgentCore](https://aws.amazon.com/bedrock/agentcore/) Terraform module provides a high-level, object-oriented approach to creating and managing Amazon Bedrock AgentCore resources using Terraform. This module abstracts away the complexity of the L1 resources and provides a higher level implementation.

## Overview

The module provides support for Amazon Bedrock AgentCore Runtime, Runtime Endpoints, and Gateways. This allows you to deploy custom container-based runtimes for your Bedrock agents and create gateways, which serve as integration points between agents and external services.

This module simplifies the process of:

- Creating and configuring Bedrock AgentCore Runtimes
- Setting up AgentCore Runtime Endpoints
- Creating and managing AgentCore Gateways
- Managing IAM permissions for your runtimes and gateways
- Configuring network access and security settings

## Features

- **Custom Container Support**: Deploy your own container images from Amazon ECR
- **Flexible Networking**: Support for both PUBLIC and VPC network modes
- **IAM Role Management**: Automatic creation of IAM roles with appropriate permissions
- **Environment Variables**: Pass configuration to your runtime container
- **JWT Authorization**: Optional JWT authorizer configuration for secure access
- **Endpoint Management**: Create and manage runtime endpoints for client access
- **Gateway Support**: Create and manage AgentCore Gateways for model context communication
- **Protocol Configuration**: Configure MCP protocol settings for gateways
- **Gateway Security**: Implement JWT authorization and KMS encryption for gateways
- **Granular Permissions**: Control gateway create, read, update, and delete permissions

## Usage

### AgentCore Runtime and Endpoint

```hcl
module "agentcore" {
  source  = "aws-ia/agentcore/aws"
  version = "0.0.1"

  # Enable Agent Core Runtime
  create_runtime = true
  runtime_name = "MyCustomRuntime"
  runtime_description = "Custom runtime for my Bedrock agent"
  runtime_container_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/bedrock/agent-runtime:latest"
  runtime_network_mode = "PUBLIC"
  # Environment variables for the runtime
  runtime_environment_variables = {
    "LOG_LEVEL" = "INFO"
    "ENV" = "production"
  }
  # Enable Agent Core Runtime Endpoint
  create_runtime_endpoint = true
  runtime_endpoint_name = "MyRuntimeEndpoint"
  runtime_endpoint_description = "Endpoint for my custom runtime"
}
```

#### With JWT Authorization

```hcl
module "agentcore" {
  source  = "aws-ia/agentcore/aws"
  version = "0.0.1"

  # Enable Agent Core Runtime
  create_runtime = true
  runtime_name = "SecureRuntime"
  runtime_container_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/bedrock/agent-runtime:latest"

  # Configure JWT authorization
  runtime_authorizer_configuration = {
    custom_jwt_authorizer = {
      discovery_url = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_example/.well-known/jwks.json"
      allowed_audience = ["client-id-1", "client-id-2"]
    }
  }

  # Enable Agent Core Runtime Endpoint
  create_runtime_endpoint = true
  runtime_endpoint_name = "SecureEndpoint"
}
```

#### With Custom IAM Role

```hcl
module "agentcore" {
  source  = "aws-ia/agentcore/aws"
  version = "0.0.1"

  # Enable Agent Core Runtime with custom IAM role
  create_runtime = true
  runtime_name = "CustomRoleRuntime"
  runtime_container_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/bedrock/agent-runtime:latest"
  runtime_role_arn = "arn:aws:iam::123456789012:role/my-custom-bedrock-role"

  # Enable Agent Core Runtime Endpoint
  create_runtime_endpoint = true
  runtime_endpoint_name = "CustomRoleEndpoint"
}
```

### AgentCore Gateway

Create and configure an MCP gateway:

```hcl
module "agentcore" {
  source  = "aws-ia/agentcore/aws"
  version = "0.0.1"

  # Enable Agent Core Gateway
  create_gateway = true
  gateway_name = "MyMCPGateway"
  gateway_description = "Gateway for Model Context Protocol connections"
  # Configure the gateway protocol (MCP)
  gateway_protocol_type = "MCP"
  gateway_protocol_configuration = {
    mcp = {
      instructions = "Custom instructions for MCP tools and resources"
      search_type = "DEFAULT"
      supported_versions = ["1.0.0"]
    }
  }
  # Optional JWT authorization
  gateway_authorizer_type = "CUSTOM_JWT"
  gateway_authorizer_configuration = {
    custom_jwt_authorizer = {
      discovery_url = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_example/.well-known/jwks.json"
      allowed_audience = ["client-id-1", "client-id-2"]
    }
  }
  # Optional KMS encryption
  gateway_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  # Manage gateway permissions
  gateway_allow_create_permissions = true
  gateway_allow_update_delete_permissions = true
}
```

## Architecture

The module creates the following resources:

1. **Agent Core Runtime**: A container-based runtime environment for your Bedrock agent
2. **IAM Role and Policy**: Permissions for the runtime to access AWS services
3. **Agent Core Runtime Endpoint**: An endpoint for client applications to interact with the runtime
4. **Agent Core Gateway**: A gateway for Model Context Protocol (MCP) connections
5. **Gateway IAM Role and Policy**: Permissions for the gateway to access AWS services

The IAM role includes permissions for:

- ECR image access
- CloudWatch Logs
- X-Ray tracing
- CloudWatch metrics
- Bedrock model invocation
- Workload identity token management

## Prerequisites

To use this module, you need:

1. An AWS account with appropriate permissions
2. Terraform >= 1.0.7
3. AWS provider >= 4.0.0
4. AWSCC provider >= 0.24.0
5. A container image in Amazon ECR (for the runtime)

## Examples

The module includes examples demonstrating different use cases:

### Agent Runtime with STRANDS Framework

The [agent-runtime](./examples/agent-runtime) example demonstrates:

- Creating an ECR repository
- Building and pushing a Docker image
- Creating a Bedrock Agent Runtime and Endpoint
- Implementing a STRANDS framework agent with tool-calling capabilities

This example includes:

- A Python implementation using the STRANDS framework
- Tools for calculations, weather information, and greetings
- Testing scripts for local and deployed testing

## Advanced Configuration

### Network Configuration

The module supports both PUBLIC and VPC network modes:

```hcl
# Public network mode (default)
runtime_network_mode = "PUBLIC"

# VPC network mode (requires additional configuration)
runtime_network_mode = "VPC"
```

### Environment Variables

Pass configuration to your runtime container:

```hcl
runtime_environment_variables = {
  "LOG_LEVEL" = "DEBUG"
  "MODEL_ID" = "anthropic.claude-3-sonnet-20240229-v1:0"
  "MAX_TOKENS" = "4096"
}
```

### Tags

Add tags to your resources:

```hcl
runtime_tags = {
  Environment = "production"
  Project     = "ai-assistants"
  Owner       = "data-science-team"
}

runtime_endpoint_tags = {
  Environment = "production"
  Project     = "ai-assistants"
  Owner       = "data-science-team"
}

gateway_tags = {
  Environment = "production"
  Project     = "ai-assistants"
  Owner       = "data-science-team"
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.24.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | >= 0.24.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.gateway_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.runtime_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.gateway_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.runtime_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.runtime_slr_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [awscc_bedrockagentcore_gateway.agent_gateway](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_gateway) | resource |
| [awscc_bedrockagentcore_runtime.agent_runtime](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_runtime) | resource |
| [awscc_bedrockagentcore_runtime_endpoint.agent_runtime_endpoint](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_runtime_endpoint) | resource |
| [random_string.solution_prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.service_linked_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_runtime_network_configuration"></a> [runtime\_network\_configuration](#input\_runtime\_network\_configuration) | value | <pre>object({<br>    security_groups = optional(list(string))<br>    subnets         = optional(list(string))<br>  })</pre> | n/a | yes |
| <a name="input_create_gateway"></a> [create\_gateway](#input\_create\_gateway) | Whether or not to create an agent core gateway. | `bool` | `false` | no |
| <a name="input_create_runtime"></a> [create\_runtime](#input\_create\_runtime) | Whether or not to create an agent core runtime. | `bool` | `false` | no |
| <a name="input_create_runtime_endpoint"></a> [create\_runtime\_endpoint](#input\_create\_runtime\_endpoint) | Whether or not to create an agent core runtime endpoint. | `bool` | `false` | no |
| <a name="input_gateway_allow_create_permissions"></a> [gateway\_allow\_create\_permissions](#input\_gateway\_allow\_create\_permissions) | Whether to allow create permissions for the gateway. | `bool` | `true` | no |
| <a name="input_gateway_allow_update_delete_permissions"></a> [gateway\_allow\_update\_delete\_permissions](#input\_gateway\_allow\_update\_delete\_permissions) | Whether to allow update and delete permissions for the gateway. | `bool` | `true` | no |
| <a name="input_gateway_authorizer_configuration"></a> [gateway\_authorizer\_configuration](#input\_gateway\_authorizer\_configuration) | Authorizer configuration for the agent core gateway. | <pre>object({<br>    custom_jwt_authorizer = object({<br>      allowed_audience = optional(list(string))<br>      allowed_clients  = optional(list(string))<br>      discovery_url    = string<br>    })<br>  })</pre> | `null` | no |
| <a name="input_gateway_authorizer_type"></a> [gateway\_authorizer\_type](#input\_gateway\_authorizer\_type) | The authorizer type for the gateway. Valid values: NONE, CUSTOM\_JWT. | `string` | `"NONE"` | no |
| <a name="input_gateway_description"></a> [gateway\_description](#input\_gateway\_description) | Description of the agent core gateway. | `string` | `null` | no |
| <a name="input_gateway_exception_level"></a> [gateway\_exception\_level](#input\_gateway\_exception\_level) | Exception level for the gateway. Valid values: PARTIAL, FULL. | `string` | `null` | no |
| <a name="input_gateway_kms_key_arn"></a> [gateway\_kms\_key\_arn](#input\_gateway\_kms\_key\_arn) | The ARN of the KMS key used to encrypt the gateway. | `string` | `null` | no |
| <a name="input_gateway_name"></a> [gateway\_name](#input\_gateway\_name) | The name of the agent core gateway. | `string` | `"TerraformBedrockAgentCoreGateway"` | no |
| <a name="input_gateway_protocol_configuration"></a> [gateway\_protocol\_configuration](#input\_gateway\_protocol\_configuration) | Protocol configuration for the agent core gateway. | <pre>object({<br>    mcp = object({<br>      instructions       = optional(string)<br>      search_type        = optional(string)<br>      supported_versions = optional(list(string))<br>    })<br>  })</pre> | `null` | no |
| <a name="input_gateway_protocol_type"></a> [gateway\_protocol\_type](#input\_gateway\_protocol\_type) | The protocol type for the gateway. Valid value: MCP. | `string` | `"MCP"` | no |
| <a name="input_gateway_role_arn"></a> [gateway\_role\_arn](#input\_gateway\_role\_arn) | Optional external IAM role ARN for the Bedrock agent core gateway. If empty, the module will create one internally. | `string` | `null` | no |
| <a name="input_gateway_tags"></a> [gateway\_tags](#input\_gateway\_tags) | A map of tag keys and values for the agent core gateway. | `map(string)` | `null` | no |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | The ARN of the IAM permission boundary for the role. | `string` | `null` | no |
| <a name="input_runtime_authorizer_configuration"></a> [runtime\_authorizer\_configuration](#input\_runtime\_authorizer\_configuration) | Authorizer configuration for the agent core runtime. | <pre>object({<br>    custom_jwt_authorizer = object({<br>      allowed_audience = optional(list(string))<br>      allowed_clients  = optional(list(string))<br>      discovery_url    = string<br>    })<br>  })</pre> | `null` | no |
| <a name="input_runtime_container_uri"></a> [runtime\_container\_uri](#input\_runtime\_container\_uri) | The ECR URI of the container for the agent core runtime. | `string` | `null` | no |
| <a name="input_runtime_description"></a> [runtime\_description](#input\_runtime\_description) | Description of the agent runtime. | `string` | `null` | no |
| <a name="input_runtime_endpoint_agent_runtime_id"></a> [runtime\_endpoint\_agent\_runtime\_id](#input\_runtime\_endpoint\_agent\_runtime\_id) | The ID of the agent core runtime associated with the endpoint. If not provided, it will use the ID of the agent runtime created by this module. | `string` | `null` | no |
| <a name="input_runtime_endpoint_description"></a> [runtime\_endpoint\_description](#input\_runtime\_endpoint\_description) | Description of the agent core runtime endpoint. | `string` | `null` | no |
| <a name="input_runtime_endpoint_name"></a> [runtime\_endpoint\_name](#input\_runtime\_endpoint\_name) | The name of the agent core runtime endpoint. | `string` | `"TerraformBedrockAgentCoreRuntimeEndpoint"` | no |
| <a name="input_runtime_endpoint_tags"></a> [runtime\_endpoint\_tags](#input\_runtime\_endpoint\_tags) | A map of tag keys and values for the agent core runtime endpoint. | `map(string)` | `null` | no |
| <a name="input_runtime_environment_variables"></a> [runtime\_environment\_variables](#input\_runtime\_environment\_variables) | Environment variables for the agent core runtime. | `map(string)` | `null` | no |
| <a name="input_runtime_name"></a> [runtime\_name](#input\_runtime\_name) | The name of the agent core runtime. | `string` | `"TerraformBedrockAgentCoreRuntime"` | no |
| <a name="input_runtime_network_mode"></a> [runtime\_network\_mode](#input\_runtime\_network\_mode) | Network mode configuration type for the agent core runtime. Valid values: PUBLIC, VPC. | `string` | `"PUBLIC"` | no |
| <a name="input_runtime_protocol_configuration"></a> [runtime\_protocol\_configuration](#input\_runtime\_protocol\_configuration) | Protocol configuration for the agent core runtime. | `string` | `null` | no |
| <a name="input_runtime_role_arn"></a> [runtime\_role\_arn](#input\_runtime\_role\_arn) | Optional external IAM role ARN for the Bedrock agent core runtime. If empty, the module will create one internally. | `string` | `null` | no |
| <a name="input_runtime_tags"></a> [runtime\_tags](#input\_runtime\_tags) | A map of tag keys and values for the agent core runtime. | `map(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_agent_gateway_arn"></a> [agent\_gateway\_arn](#output\_agent\_gateway\_arn) | ARN of the created Bedrock AgentCore Gateway |
| <a name="output_agent_gateway_id"></a> [agent\_gateway\_id](#output\_agent\_gateway\_id) | ID of the created Bedrock AgentCore Gateway |
| <a name="output_agent_gateway_status"></a> [agent\_gateway\_status](#output\_agent\_gateway\_status) | Status of the created Bedrock AgentCore Gateway |
| <a name="output_agent_gateway_status_reasons"></a> [agent\_gateway\_status\_reasons](#output\_agent\_gateway\_status\_reasons) | Status reasons of the created Bedrock AgentCore Gateway |
| <a name="output_agent_gateway_url"></a> [agent\_gateway\_url](#output\_agent\_gateway\_url) | URL of the created Bedrock AgentCore Gateway |
| <a name="output_agent_gateway_workload_identity_details"></a> [agent\_gateway\_workload\_identity\_details](#output\_agent\_gateway\_workload\_identity\_details) | Workload identity details of the created Bedrock AgentCore Gateway |
| <a name="output_agent_runtime_arn"></a> [agent\_runtime\_arn](#output\_agent\_runtime\_arn) | ARN of the created Bedrock AgentCore Runtime |
| <a name="output_agent_runtime_endpoint_arn"></a> [agent\_runtime\_endpoint\_arn](#output\_agent\_runtime\_endpoint\_arn) | ARN of the created Bedrock AgentCore Runtime Endpoint |
| <a name="output_agent_runtime_endpoint_id"></a> [agent\_runtime\_endpoint\_id](#output\_agent\_runtime\_endpoint\_id) | ID of the created Bedrock AgentCore Runtime Endpoint |
| <a name="output_agent_runtime_endpoint_live_version"></a> [agent\_runtime\_endpoint\_live\_version](#output\_agent\_runtime\_endpoint\_live\_version) | Live version of the created Bedrock AgentCore Runtime Endpoint |
| <a name="output_agent_runtime_endpoint_status"></a> [agent\_runtime\_endpoint\_status](#output\_agent\_runtime\_endpoint\_status) | Status of the created Bedrock AgentCore Runtime Endpoint |
| <a name="output_agent_runtime_endpoint_target_version"></a> [agent\_runtime\_endpoint\_target\_version](#output\_agent\_runtime\_endpoint\_target\_version) | Target version of the created Bedrock AgentCore Runtime Endpoint |
| <a name="output_agent_runtime_id"></a> [agent\_runtime\_id](#output\_agent\_runtime\_id) | ID of the created Bedrock AgentCore Runtime |
| <a name="output_agent_runtime_status"></a> [agent\_runtime\_status](#output\_agent\_runtime\_status) | Status of the created Bedrock AgentCore Runtime |
| <a name="output_agent_runtime_version"></a> [agent\_runtime\_version](#output\_agent\_runtime\_version) | Version of the created Bedrock AgentCore Runtime |
| <a name="output_agent_runtime_workload_identity_details"></a> [agent\_runtime\_workload\_identity\_details](#output\_agent\_runtime\_workload\_identity\_details) | Workload identity details of the created Bedrock AgentCore Runtime |
| <a name="output_gateway_role_arn"></a> [gateway\_role\_arn](#output\_gateway\_role\_arn) | ARN of the IAM role created for the Bedrock AgentCore Gateway |
| <a name="output_gateway_role_name"></a> [gateway\_role\_name](#output\_gateway\_role\_name) | Name of the IAM role created for the Bedrock AgentCore Gateway |
| <a name="output_runtime_role_arn"></a> [runtime\_role\_arn](#output\_runtime\_role\_arn) | ARN of the IAM role created for the Bedrock AgentCore Runtime |
| <a name="output_runtime_role_name"></a> [runtime\_role\_name](#output\_runtime\_role\_name) | Name of the IAM role created for the Bedrock AgentCore Runtime |
<!-- END_TF_DOCS -->