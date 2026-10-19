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
7. **Policy** - Cedar and Dogwood (temporal) policies that decide which gateway tools an agent may call
8. **Configuration Bundles** - Versioned agent configuration (prompts, models, settings) selected per request
9. **Workload Identity** - The identity an agent uses to obtain tokens for other services
10. **Agent Registry** - A catalog where agents, MCP servers and skills are published and discovered

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
- Dynamic Policy Engine Creation with Cedar and Dogwood (Temporal) Policies, attached to Gateways in ENFORCE or LOG\_ONLY mode
- Dynamic Configuration Bundle Creation (per-request agent configuration)
- Dynamic Workload Identity Creation, plus the identities AgentCore creates for Runtimes and Gateways as outputs
- Dynamic AWS Agent Registry Creation with Publisher IAM and optional Terraform-managed Records

## Important

- **ARM64 Architecture Required**: Amazon Bedrock AgentCore runs exclusively on AWS Graviton (ARM64) processors. When providing your own S3 packages or ECR images, you must ensure ARM64 compatibility. The module handles this automatically for module-managed CODE and CONTAINER runtimes via CodeBuild using [Terraform Actions](https://www.hashicorp.com/en/blog/day-2-infrastructure-management-with-terraform-actions).
- The names of your resources (e.g. runtimes, memories, gateways) are used as map keys to reference them. Ensure you use consistent naming throughout your configuration.
- When using **module-managed CODE runtimes**, the module automatically installs dependencies and builds ARM64-compatible packages via CodeBuild. No local Docker required.
- When using **module-managed CONTAINER runtimes**, the module automatically builds ARM64 Docker images via CodeBuild from your source directory.
- **Policy engine, policy and configuration bundle names use underscores, not hyphens** (`my_policy_engine`); gateway, gateway target and registry names use hyphens.
- Policy statements and configuration bundle component keys can reference resources created in the same module call with the `{{gateway:<name>}}`, `{{target:<name>}}` and `{{runtime:<name>}}` placeholders, which the module resolves at apply time. Gateway tools are named `<target name>___<tool>`, and gateway target names are prefixed with `project_prefix`.
- AWS Agent Registry is used through its own `agent-registry` namespace (`awscc_agentregistry_*` resources and `agent-registry:*` IAM actions). The public-preview `bedrock-agentcore` registry namespace shuts down on October 30, 2026.

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

## Basic Usage - Attach a Policy Engine to a Gateway

```hcl
module "agentcore" {
  source = "aws-ia/agentcore/aws"

  policy_engines = {
    my_policy_engine = {
      description = "Authorizes tool calls on my gateway"
      policies = [
        {
          name      = "AllowOrderLookup"
          statement = <<-EOT
            permit(
              principal,
              action == AgentCore::Action::"{{target:orders}}___get_order",
              resource == AgentCore::Gateway::"{{gateway:my-gateway}}"
            );
          EOT
        },
        {
          name             = "RefundOnlyAfterLookup"
          language         = "DOGWOOD" # temporal rule, evaluated per policy session
          enforcement_mode = "LOG_ONLY"
          statement        = <<-EOT
            permit(
              principal,
              action == AgentCore::Action::"{{target:orders}}___refund_order",
              resource == AgentCore::Gateway::"{{gateway:my-gateway}}"
            )
            when temporal {
              formerly within 10m AgentCore::Action::"{{target:orders}}___get_order"::response { eventResource: resource }
            };
          EOT
        }
      ]
    }
  }

  gateways = {
    my-gateway = {
      description = "Gateway governed by my_policy_engine"
      policy_engine_configuration = {
        policy_engine_name = "my_policy_engine"
        mode               = "ENFORCE" # or LOG_ONLY to observe first
      }
    }
  }

  gateway_targets = {
    orders = {
      gateway_name = "my-gateway"
      type         = "LAMBDA"
      # ...
    }
  }
}
```

The module grants the gateway role `bedrock-agentcore:GetPolicyEngine`, `AuthorizeAction`, `PartiallyAuthorizeActions` and `GetWorkloadAccessToken` (temporal policies). Callers of a gateway whose engine holds a temporal policy must send a policy session ID in the `x-amzn-bedrock-agentcore-policy-session-id` header.

## Basic Usage - Create Configuration Bundles

```hcl
module "agentcore" {
  source = "aws-ia/agentcore/aws"

  runtimes = {
    my_agent = {
      source_type      = "CODE"
      code_source_path = "./agent"
      code_entry_point = ["agent.py"]
    }
  }

  configuration_bundles = {
    my_agent_config = {
      description    = "Dynamic configuration for my_agent"
      commit_message = "Initial configuration"
      components = {
        "{{runtime:my_agent}}" = {
          system_prompt = "You are a helpful assistant."
          model_id      = "global.anthropic.claude-sonnet-4-5-20250929-v1:0"
        }
      }
    }
  }
}
```

A request selects a bundle version with the W3C baggage header `aws.agentcore.configbundle_arn=<arn>,aws.agentcore.configbundle_version=<version id>` (the `baggage` parameter of `InvokeAgentRuntime`, or injected by a gateway rule or A/B test); the agent reads it with `BedrockAgentCoreContext.get_config_bundle()`.

## Basic Usage - Create Workload Identities

```hcl
module "agentcore" {
  source = "aws-ia/agentcore/aws"

  workload_identities = {
    external-agent = {
      allowed_resource_oauth2_return_urls = ["https://agent.example.com/oauth2/callback"]
    }
  }
}
```

Runtimes and gateways get a workload identity automatically; their ARNs are exposed through the `runtime_workload_identity_arns` and `gateway_workload_identity_arns` outputs.

## Basic Usage - Create an Agent Registry

```hcl
module "agentcore" {
  source = "aws-ia/agentcore/aws"

  registries = {
    team-registry = {
      description          = "Agents, MCP servers and skills of my team"
      authorizer_type      = "AWS_IAM"
      auto_approve_records = false

      # IAM policy (and role) for the pipeline that publishes records at run time
      publisher = {
        trusted_services = ["codebuild.amazonaws.com"]
      }

      # Optional Terraform-managed records
      records = {
        weather-mcp-server = {
          record_type                    = "MCP"
          descriptor_data                = file("./weather-server.json")
          descriptor_data_schema_version = "2025-12-11"
        }
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
- [gateway-policy](./examples/gateway-policy) - Gateway with a policy engine, Cedar and Dogwood (temporal) policies
- [configuration-bundles](./examples/configuration-bundles) - CODE runtime whose prompt and model come from configuration bundles selected per request
- [workload-identity](./examples/workload-identity) - Runtime workload identity output plus an explicitly managed workload identity
- [agent-registry](./examples/agent-registry) - AWS Agent Registry registry, publisher IAM and a Terraform-managed MCP server record

See the [examples](./examples) directory for complete working examples.

## Contributing

See the `CONTRIBUTING.md` file for information on how to contribute.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.67.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 1.98.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.0.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.0.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.67.0 |
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | >= 1.98.0 |
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
| [aws_bedrockagentcore_workload_identity.workload_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_workload_identity) | resource |
| [aws_codebuild_project.runtime_code](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codebuild_project.runtime_container](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_ecr_lifecycle_policy.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_iam_policy.registry_publisher](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.browser](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.code_interpreter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.codebuild_code](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.codebuild_container](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.memory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.registry_publisher](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.browser_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.code_interpreter_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codebuild_code](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codebuild_container](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.gateway_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.registry_publisher](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_object.runtime_source_input](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_wafv2_web_acl_association.gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [awscc_agentregistry_registry.registry](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/agentregistry_registry) | resource |
| [awscc_agentregistry_registry_record.record](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/agentregistry_registry_record) | resource |
| [awscc_bedrockagentcore_browser_custom.browser](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_browser_custom) | resource |
| [awscc_bedrockagentcore_code_interpreter_custom.code_interpreter](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_code_interpreter_custom) | resource |
| [awscc_bedrockagentcore_configuration_bundle.bundle](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_configuration_bundle) | resource |
| [awscc_bedrockagentcore_gateway.gateway](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_gateway) | resource |
| [awscc_bedrockagentcore_memory.memory](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_memory) | resource |
| [awscc_bedrockagentcore_policy.policy](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_policy) | resource |
| [awscc_bedrockagentcore_policy_engine.policy_engine](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_policy_engine) | resource |
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
| [aws_iam_policy_document.registry_publisher_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.registry_publisher_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.runtime_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.runtime_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_browsers"></a> [browsers](#input\_browsers) | Map of AgentCore custom browsers to create. Each key is the browser name. | <pre>map(object({<br>    description        = optional(string)<br>    execution_role_arn = optional(string)<br>    network_mode       = optional(string, "PUBLIC")<br><br>    network_configuration = optional(object({<br>      security_groups = list(string)<br>      subnets         = list(string)<br>    }))<br><br>    recording_enabled = optional(bool, false)<br><br>    recording_config = optional(object({<br>      bucket = string<br>      prefix = string<br>    }))<br><br>    tags = optional(map(string))<br>  }))</pre> | `{}` | no |
| <a name="input_code_interpreters"></a> [code\_interpreters](#input\_code\_interpreters) | Map of AgentCore custom code interpreters to create. Each key is the interpreter name. | <pre>map(object({<br>    description        = optional(string)<br>    execution_role_arn = optional(string)<br>    network_mode       = optional(string, "SANDBOX")<br><br>    network_configuration = optional(object({<br>      security_groups = list(string)<br>      subnets         = list(string)<br>    }))<br><br>    tags = optional(map(string))<br>  }))</pre> | `{}` | no |
| <a name="input_configuration_bundles"></a> [configuration\_bundles](#input\_configuration\_bundles) | Map of AgentCore configuration bundles to create. Each key is the bundle name. components maps a component identifier (an AgentCore resource ARN, or a {{runtime:<name>}} / {{gateway:<name>}} placeholder for a resource created by this module) to its configuration object, which is stored as JSON. | <pre>map(object({<br>    description    = optional(string)<br>    branch_name    = optional(string) # defaults to "mainline"<br>    commit_message = optional(string)<br>    kms_key_arn    = optional(string)<br>    components     = any # map of component identifier => configuration object<br>    tags           = optional(map(string))<br>  }))</pre> | `{}` | no |
| <a name="input_debug"></a> [debug](#input\_debug) | Enable debug mode: generates .env files with actual resource IDs in code\_source\_path directories for local testing. | `bool` | `false` | no |
| <a name="input_gateway_targets"></a> [gateway\_targets](#input\_gateway\_targets) | Map of AgentCore gateway targets to create. Each key is the target name. | <pre>map(object({<br>    gateway_name             = string<br>    description              = optional(string)<br>    credential_provider_type = optional(string)<br><br>    api_key_config = optional(object({<br>      provider_arn              = string<br>      credential_location       = string<br>      credential_parameter_name = string<br>      credential_prefix         = optional(string)<br>    }))<br><br>    oauth_config = optional(object({<br>      provider_arn      = string<br>      scopes            = optional(list(string))<br>      custom_parameters = optional(map(string))<br>    }))<br><br>    type = string # "LAMBDA" or "MCP_SERVER"<br><br>    lambda_config = optional(object({<br>      lambda_arn       = string<br>      tool_schema_type = string # "INLINE" or "S3"<br><br>      inline_schema = optional(object({<br>        name        = string<br>        description = optional(string)<br><br>        input_schema = object({<br>          type        = string<br>          description = optional(string)<br>          properties  = optional(list(any))<br>          items       = optional(any)<br>        })<br><br>        output_schema = optional(object({<br>          type        = string<br>          description = optional(string)<br>          properties  = optional(list(any))<br>          items       = optional(any)<br>        }))<br>      }))<br><br>      s3_schema = optional(object({<br>        uri                     = string<br>        bucket_owner_account_id = optional(string)<br>      }))<br>    }))<br><br>    mcp_server_config = optional(object({<br>      endpoint = string<br>    }))<br>  }))</pre> | `{}` | no |
| <a name="input_gateways"></a> [gateways](#input\_gateways) | Map of AgentCore gateways to create. Each key is the gateway name. | <pre>map(object({<br>    description     = optional(string)<br>    role_arn        = optional(string)<br>    authorizer_type = optional(string, "AWS_IAM")<br>    protocol_type   = optional(string, "MCP") # "MCP", or "NONE" for a gateway with HTTP targets (runtime, passthrough)<br>    exception_level = optional(string, "DEBUG")<br>    kms_key_arn     = optional(string)<br><br>    authorizer_configuration = optional(object({<br>      custom_jwt_authorizer = object({<br>        discovery_url    = string<br>        allowed_audience = optional(list(string))<br>        allowed_clients  = optional(list(string))<br>        allowed_scopes   = optional(list(string))<br>        custom_claims = optional(list(object({<br>          inbound_token_claim_name       = string<br>          inbound_token_claim_value_type = optional(string, "STRING") # "STRING" or "STRING_ARRAY"<br>          claim_match_operator           = optional(string, "EQUALS") # "EQUALS" (STRING), "CONTAINS" or "CONTAINS_ANY" (STRING_ARRAY)<br>          match_value_string             = optional(string)<br>          match_value_string_list        = optional(list(string))<br>        })), [])<br>        # Scope advertised to clients (OAuth protected resource metadata) for each allowed scope<br>        advertised_scope_mapping = optional(map(string))<br>      })<br>    }))<br><br>    protocol_configuration = optional(object({<br>      mcp = object({<br>        instructions               = optional(string)<br>        search_type                = optional(string, "SEMANTIC")<br>        supported_versions         = optional(list(string), ["1.0.0"])<br>        session_timeout_in_seconds = optional(number) # 900-28800 (service default 3600)<br>        enable_response_streaming  = optional(bool)<br>      })<br>    }))<br><br>    interceptor_configurations = optional(list(object({<br>      interception_points = list(string)<br>      interceptor = object({<br>        lambda = object({<br>          arn = string<br>        })<br>      })<br>      input_configuration = optional(object({<br>        pass_request_headers = optional(bool, false)<br>        exclude_fields       = optional(list(string), []) # e.g. ["RESPONSE_BODY"] for HTTP and inference targets<br>      }))<br>    })), [])<br><br>    # AWS WAF: behaviour when WAF cannot be evaluated, and an optional regional web ACL to associate<br>    waf_configuration = optional(object({<br>      failure_mode = optional(string, "FAIL_CLOSE") # "FAIL_CLOSE" or "FAIL_OPEN"<br>      web_acl_arn  = optional(string)<br>    }))<br><br>    # Attach a policy engine (module-managed by name, or an existing one by ARN)<br>    policy_engine_configuration = optional(object({<br>      policy_engine_name = optional(string)<br>      policy_engine_arn  = optional(string)<br>      mode               = optional(string, "ENFORCE") # "ENFORCE" or "LOG_ONLY"<br>    }))<br><br>    tags = optional(map(string))<br>  }))</pre> | `{}` | no |
| <a name="input_memories"></a> [memories](#input\_memories) | Map of AgentCore memories to create. Each key is the memory name. NOTE: Each memory can only have ONE strategy. | <pre>map(object({<br>    description           = optional(string)<br>    event_expiry_duration = optional(number, 90)<br>    execution_role_arn    = optional(string)<br>    encryption_key_arn    = optional(string)<br><br>    strategies = optional(list(object({<br>      semantic_memory_strategy = optional(object({<br>        name        = optional(string)<br>        description = optional(string)<br>        namespaces  = optional(list(string))<br>      }))<br>      summary_memory_strategy = optional(object({<br>        name        = optional(string)<br>        description = optional(string)<br>        namespaces  = optional(list(string))<br>      }))<br>      user_preference_memory_strategy = optional(object({<br>        name        = optional(string)<br>        description = optional(string)<br>        namespaces  = optional(list(string))<br>      }))<br>      custom_memory_strategy = optional(object({<br>        name        = optional(string)<br>        description = optional(string)<br>        namespaces  = optional(list(string))<br>        configuration = optional(object({<br>          self_managed_configuration = optional(object({<br>            historical_context_window_size = optional(number, 4)<br>            invocation_configuration = object({<br>              payload_delivery_bucket_name = string<br>              topic_arn                    = string<br>            })<br>            trigger_conditions = optional(list(object({<br>              message_based_trigger = optional(object({<br>                message_count = optional(number, 1)<br>              }))<br>              time_based_trigger = optional(object({<br>                idle_session_timeout = optional(number, 10)<br>              }))<br>              token_based_trigger = optional(object({<br>                token_count = optional(number, 100)<br>              }))<br>            })))<br>          }))<br>          semantic_override = optional(object({<br>            consolidation = optional(object({<br>              append_to_prompt = optional(string)<br>              model_id         = optional(string)<br>            }))<br>            extraction = optional(object({<br>              append_to_prompt = optional(string)<br>              model_id         = optional(string)<br>            }))<br>          }))<br>          summary_override = optional(object({<br>            consolidation = optional(object({<br>              append_to_prompt = optional(string)<br>              model_id         = optional(string)<br>            }))<br>          }))<br>          user_preference_override = optional(object({<br>            consolidation = optional(object({<br>              append_to_prompt = optional(string)<br>              model_id         = optional(string)<br>            }))<br>            extraction = optional(object({<br>              append_to_prompt = optional(string)<br>              model_id         = optional(string)<br>            }))<br>          }))<br>        }))<br>      }))<br>    })), [])<br><br>    tags = optional(map(string))<br>  }))</pre> | `{}` | no |
| <a name="input_policy_engines"></a> [policy\_engines](#input\_policy\_engines) | Map of AgentCore policy engines to create. Each key is the policy engine name. Attach an engine to a gateway with the gateway's policy\_engine\_configuration. Statements may use {{gateway:<name>}}, {{target:<name>}} and {{runtime:<name>}} placeholders, which resolve to resources created by this module. | <pre>map(object({<br>    description        = optional(string)<br>    encryption_key_arn = optional(string)<br><br>    policies = optional(list(object({<br>      name             = string<br>      description      = optional(string)<br>      statement        = string                                   # Cedar or Dogwood policy text<br>      language         = optional(string, "CEDAR")                # "CEDAR" or "DOGWOOD" (temporal rules, guardrails)<br>      enforcement_mode = optional(string, "ACTIVE")               # "ACTIVE" or "LOG_ONLY"<br>      validation_mode  = optional(string, "FAIL_ON_ANY_FINDINGS") # "FAIL_ON_ANY_FINDINGS" or "IGNORE_ALL_FINDINGS"<br>    })), [])<br><br>    tags = optional(map(string))<br>  }))</pre> | `{}` | no |
| <a name="input_project_prefix"></a> [project\_prefix](#input\_project\_prefix) | Prefix for all AWS resource names created by this module. Helps identify and organize resources. | `string` | `"agentcore"` | no |
| <a name="input_registries"></a> [registries](#input\_registries) | Map of AWS Agent Registry registries to create. Each key is the registry name. The module also creates an IAM policy (and optionally a role) that lets a publishing pipeline write and submit records; records can additionally be declared inline. | <pre>map(object({<br>    description     = optional(string)<br>    authorizer_type = optional(string, "AWS_IAM") # "AWS_IAM" or "CUSTOM_JWT"<br><br>    authorizer_configuration = optional(object({<br>      custom_jwt_authorizer = object({<br>        discovery_url    = string<br>        allowed_audience = optional(list(string))<br>        allowed_clients  = optional(list(string))<br>        allowed_scopes   = optional(list(string))<br>      })<br>    }))<br><br>    auto_approve_records = optional(bool, false)<br>    kms_key_arn          = optional(string)<br><br>    auto_detection = optional(object({<br>      enabled = optional(bool, true)<br>      scope   = optional(string, "ORGANIZATION")<br>    }))<br><br>    custom_metadata_schema = optional(object({<br>      default_schema = optional(string) # JSON Schema document<br>      record_type_schema_overrides = optional(list(object({<br>        record_type = string<br>        schema      = string # JSON Schema document<br>      })), [])<br>    }))<br><br>    # IAM for the publisher (the pipeline or principal that writes records)<br>    publisher = optional(object({<br>      create_policy          = optional(bool, true)<br>      allow_approval         = optional(bool, false)<br>      trusted_principal_arns = optional(list(string), []) # IAM principals that may assume the publisher role<br>      trusted_services       = optional(list(string), []) # e.g. ["codebuild.amazonaws.com"]<br>    }), {})<br><br>    records = optional(map(object({<br>      record_type                    = string           # "MCP", "AGENT", "SKILL" or "CUSTOM"<br>      descriptor_type                = optional(string) # "MCP_SERVER", "A2A_AGENT_CARD", "AGENT_SKILLS_DEFINITION" or "CUSTOM" (defaults by record_type)<br>      description                    = optional(string)<br>      display_name                   = optional(string)<br>      record_version                 = optional(string)<br>      descriptor_data                = optional(string) # JSON document (MCP server.json, A2A agent card, skill definition or custom payload)<br>      descriptor_data_schema_version = optional(string)<br>      descriptor_source_url          = optional(string) # synchronize the descriptor from a URL instead of inline data<br>      tools_data                     = optional(string) # MCP only: tools JSON document<br>      tools_data_schema_version      = optional(string)<br>      custom_metadata                = optional(string) # JSON object matching the registry's custom metadata schema<br>      tags                           = optional(map(string))<br>    })), {})<br><br>    tags = optional(map(string))<br>  }))</pre> | `{}` | no |
| <a name="input_runtimes"></a> [runtimes](#input\_runtimes) | Map of AgentCore runtimes to create. Each key is the runtime name. | <pre>map(object({<br>    source_type = string # "CODE" or "CONTAINER"<br><br>    # CODE: Module-managed (provide source_path)<br>    code_source_path = optional(string)<br><br>    # CODE: User-managed (provide s3_bucket)<br>    code_s3_bucket     = optional(string)<br>    code_s3_key        = optional(string)<br>    code_s3_version_id = optional(string)<br><br>    # CODE: Required for both<br>    code_entry_point = optional(list(string))<br>    code_runtime     = optional(string, "PYTHON_3_11") # Default to PYTHON_3_11<br><br>    # CONTAINER: Module-managed (provide source_path)<br>    container_source_path     = optional(string)<br>    container_dockerfile_name = optional(string, "Dockerfile")<br>    container_image_tag       = optional(string, "latest")<br><br>    # CONTAINER: User-managed (provide image_uri)<br>    container_image_uri = optional(string)<br><br>    # Shared configuration<br>    execution_role_arn     = optional(string) # Required for user-managed<br>    description            = optional(string)<br>    execution_network_mode = optional(string, "PUBLIC")<br>    execution_network_config = optional(object({<br>      security_groups = list(string)<br>      subnets         = list(string)<br>    }))<br>    environment_variables = optional(map(string), {})<br><br>    # Protocol the agent serves ("HTTP", "MCP", "A2A" or "AGUI"; service default HTTP)<br>    protocol_configuration = optional(string)<br>    platform_version       = optional(string)<br><br>    # Session lifecycle (seconds). Service defaults: 900 idle, 28800 max lifetime<br>    lifecycle_configuration = optional(object({<br>      idle_runtime_session_timeout = optional(number)<br>      max_lifetime                 = optional(number)<br>    }))<br><br>    # HTTP headers forwarded to the agent (max 20; x-amzn-* only with the X-Amzn-Bedrock-AgentCore-Runtime-Custom- prefix)<br>    request_header_allowlist = optional(list(string))<br><br>    # Inbound JWT authorization (default: AWS IAM / SigV4)<br>    authorizer_configuration = optional(object({<br>      custom_jwt_authorizer = object({<br>        discovery_url    = string<br>        allowed_audience = optional(list(string))<br>        allowed_clients  = optional(list(string))<br>        allowed_scopes   = optional(list(string))<br>        custom_claims = optional(list(object({<br>          inbound_token_claim_name       = string<br>          inbound_token_claim_value_type = optional(string, "STRING") # "STRING" or "STRING_ARRAY"<br>          claim_match_operator           = optional(string, "EQUALS") # "EQUALS" (STRING), "CONTAINS" or "CONTAINS_ANY" (STRING_ARRAY)<br>          match_value_string             = optional(string)<br>          match_value_string_list        = optional(list(string))<br>        })), [])<br>        # Only accept requests whose identity chain includes these workloads (e.g. a gateway)<br>        allowed_workload_configuration = optional(object({<br>          workload_identities      = optional(list(string), [])<br>          hosting_environment_arns = optional(list(string), [])<br>        }))<br>      })<br>    }))<br><br>    create_endpoint      = optional(bool, true)<br>    endpoint_description = optional(string)<br>    tags                 = optional(map(string))<br>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources created by this module. | `map(string)` | <pre>{<br>  "IaC": "Terraform",<br>  "ModuleName": "terraform-aws-agentcore",<br>  "ModuleSource": "https://github.com/aws-ia/terraform-aws-agentcore",<br>  "ModuleVersion": ""<br>}</pre> | no |
| <a name="input_workload_identities"></a> [workload\_identities](#input\_workload\_identities) | Map of AgentCore workload identities to create. Each key is the workload identity name. Runtimes and gateways get a workload identity automatically; declare identities here for agents that run elsewhere or that need OAuth2 return URLs for 3-legged OAuth flows. | <pre>map(object({<br>    allowed_resource_oauth2_return_urls = optional(list(string), [])<br>    tags                                = optional(map(string))<br>  }))</pre> | `{}` | no |

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
| <a name="output_configuration_bundle_arns"></a> [configuration\_bundle\_arns](#output\_configuration\_bundle\_arns) | Map of configuration bundle names to their ARNs (use with the aws.agentcore.configbundle\_arn baggage key) |
| <a name="output_configuration_bundle_ids"></a> [configuration\_bundle\_ids](#output\_configuration\_bundle\_ids) | Map of configuration bundle names to their IDs |
| <a name="output_configuration_bundle_version_ids"></a> [configuration\_bundle\_version\_ids](#output\_configuration\_bundle\_version\_ids) | Map of configuration bundle names to their current version IDs (use with the aws.agentcore.configbundle\_version baggage key) |
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
| <a name="output_gateway_web_acl_arns"></a> [gateway\_web\_acl\_arns](#output\_gateway\_web\_acl\_arns) | Map of gateway names to the ARN of the AWS WAF web ACL associated with them (empty string when none) |
| <a name="output_gateway_workload_identity_arns"></a> [gateway\_workload\_identity\_arns](#output\_gateway\_workload\_identity\_arns) | Map of gateway names to the ARN of the workload identity AgentCore created for the gateway |
| <a name="output_memory_arns"></a> [memory\_arns](#output\_memory\_arns) | Map of memory names to their ARNs |
| <a name="output_memory_ids"></a> [memory\_ids](#output\_memory\_ids) | Map of memory names to their IDs |
| <a name="output_memory_role_arns"></a> [memory\_role\_arns](#output\_memory\_role\_arns) | Map of memory names to their IAM role ARNs |
| <a name="output_memory_statuses"></a> [memory\_statuses](#output\_memory\_statuses) | Map of memory names to their statuses |
| <a name="output_policy_arns"></a> [policy\_arns](#output\_policy\_arns) | Map of '<policy engine name>/<policy name>' to policy ARNs |
| <a name="output_policy_engine_arns"></a> [policy\_engine\_arns](#output\_policy\_engine\_arns) | Map of policy engine names to their ARNs |
| <a name="output_policy_engine_ids"></a> [policy\_engine\_ids](#output\_policy\_engine\_ids) | Map of policy engine names to their IDs |
| <a name="output_policy_engine_statuses"></a> [policy\_engine\_statuses](#output\_policy\_engine\_statuses) | Map of policy engine names to their statuses |
| <a name="output_policy_ids"></a> [policy\_ids](#output\_policy\_ids) | Map of '<policy engine name>/<policy name>' to policy IDs |
| <a name="output_policy_statuses"></a> [policy\_statuses](#output\_policy\_statuses) | Map of '<policy engine name>/<policy name>' to policy statuses |
| <a name="output_registry_arns"></a> [registry\_arns](#output\_registry\_arns) | Map of registry names to their ARNs |
| <a name="output_registry_ids"></a> [registry\_ids](#output\_registry\_ids) | Map of registry names to their IDs |
| <a name="output_registry_publisher_policy_arns"></a> [registry\_publisher\_policy\_arns](#output\_registry\_publisher\_policy\_arns) | Map of registry names to the ARN of the IAM policy that lets a publisher write and submit records |
| <a name="output_registry_publisher_role_arns"></a> [registry\_publisher\_role\_arns](#output\_registry\_publisher\_role\_arns) | Map of registry names to the ARN of the publisher IAM role (created when trusted principals or services are given) |
| <a name="output_registry_record_arns"></a> [registry\_record\_arns](#output\_registry\_record\_arns) | Map of '<registry name>/<record name>' to registry record ARNs |
| <a name="output_registry_record_ids"></a> [registry\_record\_ids](#output\_registry\_record\_ids) | Map of '<registry name>/<record name>' to registry record IDs |
| <a name="output_registry_statuses"></a> [registry\_statuses](#output\_registry\_statuses) | Map of registry names to their statuses |
| <a name="output_runtime_arns"></a> [runtime\_arns](#output\_runtime\_arns) | Map of runtime names to their ARNs |
| <a name="output_runtime_ids"></a> [runtime\_ids](#output\_runtime\_ids) | Map of runtime names to their IDs |
| <a name="output_runtime_role_arns"></a> [runtime\_role\_arns](#output\_runtime\_role\_arns) | Map of runtime names to their IAM role ARNs |
| <a name="output_runtime_versions"></a> [runtime\_versions](#output\_runtime\_versions) | Map of runtime names to their versions |
| <a name="output_runtime_workload_identity_arns"></a> [runtime\_workload\_identity\_arns](#output\_runtime\_workload\_identity\_arns) | Map of runtime names to the ARN of the workload identity AgentCore created for the runtime |
| <a name="output_s3_bucket_names"></a> [s3\_bucket\_names](#output\_s3\_bucket\_names) | Map of runtime names to their S3 bucket names |
| <a name="output_workload_identity_arns"></a> [workload\_identity\_arns](#output\_workload\_identity\_arns) | Map of workload identity names to their ARNs |
<!-- END_TF_DOCS -->