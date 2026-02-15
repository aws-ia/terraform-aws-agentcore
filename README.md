<!-- BEGIN_TF_DOCS -->
# Amazon Bedrock AgentCore Terraform Module

Terraform module for creating and managing Amazon Bedrock AgentCore resources. AgentCore is AWS's managed service for running AI agents - you provide the agent code, AWS runs it for you.

## Understanding AgentCore

**Core Components:**

1. **Runtime** - WHERE your agent code runs (Python from S3 or Docker from ECR)
2. **Runtime Endpoint** - HOW you invoke your agent (AWS SDK, not HTTP routes)
3. **Memory** - Persistent context across conversations (short-term + long-term)
4. **Gateway** - Integration with external tools/APIs (Model Context Protocol)
5. **Browser** - Web browsing capability for agents
6. **Code Interpreter** - Secure Python code execution

**How It Works:**

```
1. Deploy: terraform apply (creates runtime + endpoint)
2. Invoke: boto3.client('bedrock-agent-runtime').invoke_agent(...)
3. Agent runs your code and returns response
```

**No API Gateway or Lambda needed** - AgentCore Runtime Endpoint IS the API.

## Features

- Dynamic Runtime Creation (CODE and CONTAINER types)
- Dynamic Runtime Endpoint Creation
- Dynamic Memory Creation with Multiple Strategies
- Dynamic Gateway Creation with MCP Protocol Support
- Dynamic Code Interpreter Creation
- Dynamic Browser Creation
- Automatic ARM64 Build Pipeline for CODE Runtimes via [Terraform Actions](https://www.hashicorp.com/en/blog/day-2-infrastructure-management-with-terraform-actions)
- Automatic ARM64 Container Builds via CodeBuild using [Terraform Actions](https://www.hashicorp.com/en/blog/day-2-infrastructure-management-with-terraform-actions)
- IAM Role Management with Appropriate Permissions
- VPC and Public Network Mode Support
- JWT and IAM Authorization Support

## Important

- **ARM64 Architecture Required**: Amazon Bedrock AgentCore runs exclusively on AWS Graviton (ARM64) processors. When providing your own S3 packages or ECR images, you must ensure ARM64 compatibility. The module handles this automatically for module-managed CODE and CONTAINER runtimes via CodeBuild using [Terraform Actions](https://www.hashicorp.com/en/blog/day-2-infrastructure-management-with-terraform-actions).
- The names of your resources (e.g. runtimes, memories, gateways) are used as map keys to reference them. Ensure you use consistent naming throughout your configuration.
- When using **module-managed CODE runtimes**, the module automatically installs dependencies and builds ARM64-compatible packages via CodeBuild. No local Docker required.
- When using **module-managed CONTAINER runtimes**, the module automatically builds ARM64 Docker images via CodeBuild from your source directory.

## Basic Usage - Create Runtime with Endpoint

```hcl
module "agentcore" {
  source = "aws-ia/agentcore/aws"

  runtimes = {
    my_agent = {
      source_type      = "CODE"
      code_source_path = "./agent"
      code_entry_point = ["agent.py"]
      code_runtime     = "PYTHON_3_11"
      description      = "My AI agent runtime"
      create_endpoint  = true
    }
  }
}
```

## Basic Usage - Create Memory with Strategies

```hcl
module "agentcore" {
  source = "aws-ia/agentcore/aws"

  memories = {
    agent_memory = {
      description           = "Memory for my agent"
      event_expiry_duration = 90
      strategies = [
        {
          semantic_memory_strategy = {
            name        = "semantic_strategy"
            description = "Extract factual knowledge"
            namespaces  = ["/strategies/{memoryStrategyId}/actors/{actorId}"]
          }
        }
      ]
    }
  }
}
```

## Basic Usage - Create Gateway with MCP Protocol

```hcl
module "agentcore" {
  source = "aws-ia/agentcore/aws"

  gateways = {
    mcp_gateway = {
      description   = "Gateway for external tools"
      protocol_type = "MCP"
      protocol_configuration = {
        mcp = {
          instructions       = "Gateway for tool integration"
          search_type        = "DEFAULT"
          supported_versions = ["2025-11-25"]
        }
      }
      authorizer_type = "AWS_IAM"
    }
  }
}
```

## Basic Usage - Create Code Interpreter

```hcl
module "agentcore" {
  source = "aws-ia/agentcore/aws"

  code_interpreters = {
    my_interpreter = {
      description  = "Secure code execution environment"
      network_mode = "SANDBOX"
    }
  }
}
```

## Basic Usage - Create Browser

```hcl
module "agentcore" {
  source = "aws-ia/agentcore/aws"

  browsers = {
    my_browser = {
      description       = "Web browsing for agents"
      network_mode      = "PUBLIC"
      recording_enabled = true
      recording_config = {
        bucket = "my-recordings-bucket"
        prefix = "sessions/"
      }
    }
  }
}
```

## Examples

The module includes several examples demonstrating different use cases:

- [basic-code-runtime](./examples/basic-code-runtime) - CODE runtime with automatic ARM64 build
- [basic-container-runtime](./examples/basic-container-runtime) - CONTAINER runtime with automatic ARM64 Docker build
- [complete](./examples/complete) - All resource types: runtimes, memories, gateways, gateway targets, browsers, code interpreters

See the [examples](./examples) directory for complete working examples.

## Contributing

See the `CONTRIBUTING.md` file for information on how to contribute.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.18.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 1.30.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.0.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.0.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.18.0 |
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | >= 1.30.0 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.0.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.6.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_bedrockagentcore_gateway_target.gateway_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_gateway_target) | resource |
| [aws_codebuild_project.runtime_code](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codebuild_project.runtime_container](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_ecr_lifecycle_policy.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_iam_role.browser](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.code_interpreter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.codebuild_code](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.codebuild_container](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.memory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.browser_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.code_interpreter_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codebuild_code](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codebuild_container](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.gateway_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_s3_bucket.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_object.runtime_source_input](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [awscc_bedrockagentcore_browser_custom.browser](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_browser_custom) | resource |
| [awscc_bedrockagentcore_code_interpreter_custom.code_interpreter](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_code_interpreter_custom) | resource |
| [awscc_bedrockagentcore_gateway.gateway](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_gateway) | resource |
| [awscc_bedrockagentcore_memory.memory](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_memory) | resource |
| [awscc_bedrockagentcore_runtime.runtime_code](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_runtime) | resource |
| [awscc_bedrockagentcore_runtime.runtime_container](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_runtime) | resource |
| [awscc_bedrockagentcore_runtime_endpoint.runtime](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_runtime_endpoint) | resource |
| [local_file.debug_env](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.test_runtime_script](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_string.bucket_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_string.solution_prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [terraform_data.build_trigger_code](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.build_trigger_container](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [time_sleep.browser_iam_role_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.code_interpreter_iam_role_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.codebuild_iam_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.gateway_iam_policy_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.iam_role_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.memory_iam_role_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [archive_file.runtime_source](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.browser_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.browser_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.code_interpreter_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.code_interpreter_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild_code_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild_container_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.gateway_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.gateway_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.memory_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.runtime_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.runtime_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_browsers"></a> [browsers](#input\_browsers) | Map of AgentCore custom browsers to create. Each key is the browser name. | <pre>map(object({<br/>    description          = optional(string)<br/>    execution_role_arn   = optional(string)<br/>    network_mode         = optional(string, "PUBLIC")<br/>    <br/>    network_configuration = optional(object({<br/>      security_groups = list(string)<br/>      subnets         = list(string)<br/>    }))<br/>    <br/>    recording_enabled = optional(bool, false)<br/>    <br/>    recording_config = optional(object({<br/>      bucket = string<br/>      prefix = string<br/>    }))<br/>    <br/>    tags = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_code_interpreters"></a> [code\_interpreters](#input\_code\_interpreters) | Map of AgentCore custom code interpreters to create. Each key is the interpreter name. | <pre>map(object({<br/>    description          = optional(string)<br/>    execution_role_arn   = optional(string)<br/>    network_mode         = optional(string, "SANDBOX")<br/>    <br/>    network_configuration = optional(object({<br/>      security_groups = list(string)<br/>      subnets         = list(string)<br/>    }))<br/>    <br/>    tags = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_debug"></a> [debug](#input\_debug) | Enable debug mode: generates .env files with actual resource IDs in code\_source\_path directories for local testing. | `bool` | `false` | no |
| <a name="input_gateway_targets"></a> [gateway\_targets](#input\_gateway\_targets) | Map of AgentCore gateway targets to create. Each key is the target name. | <pre>map(object({<br/>    gateway_name                = string<br/>    description                 = optional(string)<br/>    credential_provider_type    = optional(string)<br/>    <br/>    api_key_config = optional(object({<br/>      provider_arn              = string<br/>      credential_location       = string<br/>      credential_parameter_name = string<br/>      credential_prefix         = optional(string)<br/>    }))<br/>    <br/>    oauth_config = optional(object({<br/>      provider_arn      = string<br/>      scopes            = optional(list(string))<br/>      custom_parameters = optional(map(string))<br/>    }))<br/>    <br/>    type = string # "LAMBDA" or "MCP_SERVER"<br/>    <br/>    lambda_config = optional(object({<br/>      lambda_arn       = string<br/>      tool_schema_type = string # "INLINE" or "S3"<br/>      <br/>      inline_schema = optional(object({<br/>        name        = string<br/>        description = optional(string)<br/>        <br/>        input_schema = object({<br/>          type        = string<br/>          description = optional(string)<br/>          properties  = optional(list(any))<br/>          items       = optional(any)<br/>        })<br/>        <br/>        output_schema = optional(object({<br/>          type        = string<br/>          description = optional(string)<br/>          properties  = optional(list(any))<br/>          items       = optional(any)<br/>        }))<br/>      }))<br/>      <br/>      s3_schema = optional(object({<br/>        uri                     = string<br/>        bucket_owner_account_id = optional(string)<br/>      }))<br/>    }))<br/>    <br/>    mcp_server_config = optional(object({<br/>      endpoint = string<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_gateways"></a> [gateways](#input\_gateways) | Map of AgentCore gateways to create. Each key is the gateway name. | <pre>map(object({<br/>    description      = optional(string)<br/>    role_arn         = optional(string)<br/>    authorizer_type  = optional(string, "AWS_IAM")<br/>    protocol_type    = optional(string, "MCP")<br/>    exception_level  = optional(string, "DEBUG")<br/>    kms_key_arn      = optional(string)<br/>    <br/>    authorizer_configuration = optional(object({<br/>      custom_jwt_authorizer = object({<br/>        allowed_audience = list(string)<br/>        allowed_clients  = optional(list(string))<br/>        discovery_url    = string<br/>      })<br/>    }))<br/>    <br/>    protocol_configuration = optional(object({<br/>      mcp = object({<br/>        instructions       = optional(string)<br/>        search_type        = optional(string, "SEMANTIC")<br/>        supported_versions = optional(list(string), ["1.0.0"])<br/>      })<br/>    }))<br/>    <br/>    interceptor_configurations = optional(list(object({<br/>      interception_points = list(string)<br/>      interceptor = object({<br/>        lambda = object({<br/>          arn = string<br/>        })<br/>      })<br/>      input_configuration = optional(object({<br/>        pass_request_headers = optional(bool, false)<br/>      }))<br/>    })), [])<br/>    <br/>    tags = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_memories"></a> [memories](#input\_memories) | Map of AgentCore memories to create. Each key is the memory name. NOTE: Each memory can only have ONE strategy. | <pre>map(object({<br/>    description           = optional(string)<br/>    event_expiry_duration = optional(number, 90)<br/>    execution_role_arn    = optional(string)<br/>    encryption_key_arn    = optional(string)<br/>    <br/>    strategies = optional(list(object({<br/>      semantic_memory_strategy = optional(object({<br/>        name        = optional(string)<br/>        description = optional(string)<br/>        namespaces  = optional(list(string))<br/>      }))<br/>      summary_memory_strategy = optional(object({<br/>        name        = optional(string)<br/>        description = optional(string)<br/>        namespaces  = optional(list(string))<br/>      }))<br/>      user_preference_memory_strategy = optional(object({<br/>        name        = optional(string)<br/>        description = optional(string)<br/>        namespaces  = optional(list(string))<br/>      }))<br/>      custom_memory_strategy = optional(object({<br/>        name        = optional(string)<br/>        description = optional(string)<br/>        namespaces  = optional(list(string))<br/>        configuration = optional(object({<br/>          self_managed_configuration = optional(object({<br/>            historical_context_window_size = optional(number, 4)<br/>            invocation_configuration = object({<br/>              payload_delivery_bucket_name = string<br/>              topic_arn                    = string<br/>            })<br/>            trigger_conditions = optional(list(object({<br/>              message_based_trigger = optional(object({<br/>                message_count = optional(number, 1)<br/>              }))<br/>              time_based_trigger = optional(object({<br/>                idle_session_timeout = optional(number, 10)<br/>              }))<br/>              token_based_trigger = optional(object({<br/>                token_count = optional(number, 100)<br/>              }))<br/>            })))<br/>          }))<br/>          semantic_override = optional(object({<br/>            consolidation = optional(object({<br/>              append_to_prompt = optional(string)<br/>              model_id         = optional(string)<br/>            }))<br/>            extraction = optional(object({<br/>              append_to_prompt = optional(string)<br/>              model_id         = optional(string)<br/>            }))<br/>          }))<br/>          summary_override = optional(object({<br/>            consolidation = optional(object({<br/>              append_to_prompt = optional(string)<br/>              model_id         = optional(string)<br/>            }))<br/>          }))<br/>          user_preference_override = optional(object({<br/>            consolidation = optional(object({<br/>              append_to_prompt = optional(string)<br/>              model_id         = optional(string)<br/>            }))<br/>            extraction = optional(object({<br/>              append_to_prompt = optional(string)<br/>              model_id         = optional(string)<br/>            }))<br/>          }))<br/>        }))<br/>      }))<br/>    })), [])<br/>    <br/>    tags = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_project_prefix"></a> [project\_prefix](#input\_project\_prefix) | Prefix for all AWS resource names created by this module. Helps identify and organize resources. | `string` | `"agentcore"` | no |
| <a name="input_runtimes"></a> [runtimes](#input\_runtimes) | Map of AgentCore runtimes to create. Each key is the runtime name. | <pre>map(object({<br/>    source_type = string # "CODE" or "CONTAINER"<br/><br/>    # CODE: Module-managed (provide source_path)<br/>    code_source_path = optional(string)<br/><br/>    # CODE: User-managed (provide s3_bucket)<br/>    code_s3_bucket     = optional(string)<br/>    code_s3_key        = optional(string)<br/>    code_s3_version_id = optional(string)<br/><br/>    # CODE: Required for both<br/>    code_entry_point = optional(list(string))<br/>    code_runtime     = optional(string, "PYTHON_3_11") # Default to PYTHON_3_11<br/><br/>    # CONTAINER: Module-managed (provide source_path)<br/>    container_source_path     = optional(string)<br/>    container_dockerfile_name = optional(string, "Dockerfile")<br/>    container_image_tag       = optional(string, "latest")<br/><br/>    # CONTAINER: User-managed (provide image_uri)<br/>    container_image_uri = optional(string)<br/><br/>    # Shared configuration<br/>    execution_role_arn       = optional(string) # Required for user-managed<br/>    description              = optional(string)<br/>    execution_network_mode   = optional(string, "PUBLIC")<br/>    execution_network_config = optional(object({<br/>      security_groups = list(string)<br/>      subnets         = list(string)<br/>    }))<br/>    environment_variables = optional(map(string), {})<br/><br/>    create_endpoint      = optional(bool, true)<br/>    endpoint_description = optional(string)<br/>    tags                 = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources created by this module. | `map(string)` | <pre>{<br/>  "IaC": "Terraform",<br/>  "ModuleName": "terraform-aws-agentcore",<br/>  "ModuleSource": "https://github.com/aws-ia/terraform-aws-agentcore",<br/>  "ModuleVersion": ""<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_browser_arns"></a> [browser\_arns](#output\_browser\_arns) | Map of browser names to their ARNs |
| <a name="output_browser_ids"></a> [browser\_ids](#output\_browser\_ids) | Map of browser names to their IDs |
| <a name="output_browser_role_arns"></a> [browser\_role\_arns](#output\_browser\_role\_arns) | Map of browser names to their IAM role ARNs |
| <a name="output_browser_statuses"></a> [browser\_statuses](#output\_browser\_statuses) | Map of browser names to their statuses |
| <a name="output_code_interpreter_arns"></a> [code\_interpreter\_arns](#output\_code\_interpreter\_arns) | Map of code interpreter names to their ARNs |
| <a name="output_code_interpreter_ids"></a> [code\_interpreter\_ids](#output\_code\_interpreter\_ids) | Map of code interpreter names to their IDs |
| <a name="output_code_interpreter_role_arns"></a> [code\_interpreter\_role\_arns](#output\_code\_interpreter\_role\_arns) | Map of code interpreter names to their IAM role ARNs |
| <a name="output_code_interpreter_statuses"></a> [code\_interpreter\_statuses](#output\_code\_interpreter\_statuses) | Map of code interpreter names to their statuses |
| <a name="output_codebuild_project_names"></a> [codebuild\_project\_names](#output\_codebuild\_project\_names) | Map of CONTAINER runtime names to their CodeBuild project names |
| <a name="output_ecr_repository_urls"></a> [ecr\_repository\_urls](#output\_ecr\_repository\_urls) | Map of CONTAINER runtime names to their ECR repository URLs |
| <a name="output_endpoint_arns"></a> [endpoint\_arns](#output\_endpoint\_arns) | Map of runtime names to their endpoint ARNs |
| <a name="output_endpoint_ids"></a> [endpoint\_ids](#output\_endpoint\_ids) | Map of runtime names to their endpoint IDs |
| <a name="output_gateway_arns"></a> [gateway\_arns](#output\_gateway\_arns) | Map of gateway names to their ARNs |
| <a name="output_gateway_ids"></a> [gateway\_ids](#output\_gateway\_ids) | Map of gateway names to their IDs |
| <a name="output_gateway_role_arns"></a> [gateway\_role\_arns](#output\_gateway\_role\_arns) | Map of gateway names to their IAM role ARNs |
| <a name="output_gateway_statuses"></a> [gateway\_statuses](#output\_gateway\_statuses) | Map of gateway names to their statuses |
| <a name="output_gateway_target_gateway_ids"></a> [gateway\_target\_gateway\_ids](#output\_gateway\_target\_gateway\_ids) | Map of gateway target names to their associated gateway IDs |
| <a name="output_gateway_target_ids"></a> [gateway\_target\_ids](#output\_gateway\_target\_ids) | Map of gateway target names to their IDs |
| <a name="output_gateway_target_names"></a> [gateway\_target\_names](#output\_gateway\_target\_names) | Map of gateway target names to their resource names |
| <a name="output_gateway_urls"></a> [gateway\_urls](#output\_gateway\_urls) | Map of gateway names to their URLs |
| <a name="output_memory_arns"></a> [memory\_arns](#output\_memory\_arns) | Map of memory names to their ARNs |
| <a name="output_memory_ids"></a> [memory\_ids](#output\_memory\_ids) | Map of memory names to their IDs |
| <a name="output_memory_role_arns"></a> [memory\_role\_arns](#output\_memory\_role\_arns) | Map of memory names to their IAM role ARNs |
| <a name="output_memory_statuses"></a> [memory\_statuses](#output\_memory\_statuses) | Map of memory names to their statuses |
| <a name="output_runtime_arns"></a> [runtime\_arns](#output\_runtime\_arns) | Map of runtime names to their ARNs |
| <a name="output_runtime_ids"></a> [runtime\_ids](#output\_runtime\_ids) | Map of runtime names to their IDs |
| <a name="output_runtime_role_arns"></a> [runtime\_role\_arns](#output\_runtime\_role\_arns) | Map of runtime names to their IAM role ARNs |
| <a name="output_runtime_versions"></a> [runtime\_versions](#output\_runtime\_versions) | Map of runtime names to their versions |
| <a name="output_s3_bucket_names"></a> [s3\_bucket\_names](#output\_s3\_bucket\_names) | Map of runtime names to their S3 bucket names |
<!-- END_TF_DOCS -->