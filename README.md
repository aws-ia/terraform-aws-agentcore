<!-- BEGIN_TF_DOCS -->
# Bedrock AgentCore Module

The [Amazon Bedrock AgentCore](https://aws.amazon.com/bedrock/agentcore/) Terraform module provides a high-level, object-oriented approach to creating and managing Amazon Bedrock AgentCore resources using Terraform. This module abstracts away the complexity of the L1 resources and provides a higher level implementation.

## Overview

The module provides support for Amazon Bedrock AgentCore Runtime, Runtime Endpoints, Memories, and Gateways. This allows you to deploy custom container-based runtimes for your Bedrock agents, create memory resources that provide long-term contextual awareness, and establish gateways which serve as integration points between agents and external services.

This module simplifies the process of:

- Creating and configuring Bedrock AgentCore Runtimes
- Setting up AgentCore Runtime Endpoints
- Implementing AgentCore Memory with various memory strategies
- Creating and managing AgentCore Gateways
- Managing IAM permissions for your runtimes, memories, and gateways
- Configuring network access and security settings

## Features

- **Custom Container Support**: Deploy your own container images from Amazon ECR
- **Flexible Networking**: Support for both PUBLIC and VPC network modes for runtimes, and SANDBOX and VPC modes for code interpreters
- **IAM Role Management**: Automatic creation of IAM roles with appropriate permissions
- **Environment Variables**: Pass configuration to your runtime container
- **JWT Authorization**: Optional JWT authorizer configuration for secure access
- **Endpoint Management**: Create and manage runtime endpoints for client access
- **Memory Management**: Create and configure memory resources for persistent contextual awareness
- **Multiple Memory Strategies**: Support for semantic, summary, user preference, and custom memory strategies
- **Namespace Organization**: Organize memory data with customizable namespaces for different actors and sessions
- **Custom Memory Consolidation**: Override prompts and models for memory extraction and consolidation
- **Gateway Support**: Create and manage AgentCore Gateways for model context communication
- **Protocol Configuration**: Configure MCP protocol settings for gateways
- **Gateway Security**: Implement JWT authorization and KMS encryption for gateways
- **Granular Permissions**: Control gateway create, read, update, and delete permissions
- **OAuth2 Outbound Authorization**: Configure OAuth client for gateway outbound authorization
- **API Key Outbound Authorization**: Configure API key for gateway outbound authorization
- **Code Interpreter**: Create and manage custom code interpreter resources for Bedrock agents
- **Browser Custom**: Create and manage custom browser resources for Bedrock agents with recording capabilities

## Usage

### AgentCore Runtime and Endpoint

```hcl
module "agentcore" {
  source  = "aws-ia/agentcore/aws"
  version = "0.0.3"

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
  version = "0.0.3"

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
  version = "0.0.3"

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
  version = "0.0.3"

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
  gateway_kms_key_arn = "<INSERT_KEY_HERE>"

  # Manage gateway permissions
  gateway_allow_create_permissions = true
  gateway_allow_update_delete_permissions = true
}
```

#### Automatic Cognito User Pool Creation

The module can automatically create a Cognito User Pool to handle JWT authentication when no JWT auth information is provided:

```hcl
module "agentcore" {
  source  = "aws-ia/agentcore/aws"
  version = "0.0.3"

  # Enable Agent Core Gateway
  create_gateway = true
  gateway_name = "GatewayWithAutoCognito"
  gateway_authorizer_type = "CUSTOM_JWT"
  # No gateway_authorizer_configuration - a Cognito User Pool will be created automatically

}
```

In this scenario, the module will:

1. Create a Cognito User Pool
2. Configure a domain for the User Pool
3. Set up a User Pool client with the necessary OAuth configuration
4. Configure the gateway's JWT authorizer to use the User Pool

### AgentCore Memory

Memory is a critical component of intelligence. While Large Language Models (LLMs) have impressive capabilities, they lack persistent memory across conversations. Amazon Bedrock AgentCore Memory addresses this limitation by providing a managed service that enables AI agents to maintain context over time, remember important facts, and deliver consistent, personalized experiences.

AgentCore Memory operates on two levels:

- **Short-Term Memory**: Immediate conversation context and session-based information that provides continuity within a single interaction or closely related sessions.
- **Long-Term Memory**: Persistent information extracted and stored across multiple conversations, including facts, preferences, and summaries that enable personalized experiences over time.

When you interact with the memory, you store interactions in Short-Term Memory (STM) instantly. These interactions can include everything from user messages, assistant responses, to tool actions.

To write to long-term memory, you need to configure extraction strategies which define how and where to store information from conversations for future use. These strategies are asynchronously processed from raw events after every few turns based on the strategy that was selected. You can't create long term memory records directly, as they are extracted asynchronously by AgentCore Memory.

#### Basic Memory Creation

Below you can find how to configure a simple short-term memory (STM) with no long-term memory extraction strategies. Note how you set `memory_event_expiry_duration`, which defines the time in days the events will be stored in the short-term memory before they expire.

```hcl
module "agentcore" {
  source  = "aws-ia/agentcore/aws"
  version = "0.0.3"

  # Create a basic memory with default settings, no LTM strategies
  create_memory = true
  memory_name = "my_memory"
  memory_description = "A memory for storing user interactions for a period of 90 days"
  memory_event_expiry_duration = 90
}
```

Basic Memory with Custom KMS Encryption

```hcl
# Create a custom KMS key for encryption
resource "aws_kms_key" "memory_encryption_key" {
  enable_key_rotation = true
  description         = "KMS key for memory encryption"
}

module "agentcore" {
  source  = "aws-ia/agentcore/aws"
  version = "0.0.3"

  # Create memory with custom encryption
  create_memory = true
  memory_name = "my_encrypted_memory"
  memory_description = "Memory with custom KMS encryption"
  memory_event_expiry_duration = 90
  memory_kms_key_arn = aws_kms_key.memory_encryption_key.arn
}
```

#### Memory with Built-in Strategies

The library provides three built-in LTM strategies. These are default strategies for organizing and extracting memory data, each optimized for specific use cases.

For example: An agent helps multiple users with cloud storage setup. From these conversations, see how each strategy processes users expressing confusion about account connection:

#### Summarization Strategy

This strategy compresses conversations into concise overviews, preserving essential context and key insights for quick recall. Extracted memory example: Users confused by cloud setup during onboarding.

- Extracts concise summaries to preserve critical context and key insights
- Namespace: `/strategies/{memoryStrategyId}/actors/{actorId}/sessions/{sessionId}`

#### Semantic Memory Strategy

Distills general facts, concepts, and underlying meanings from raw conversational data, presenting the information in a context-independent format. Extracted memory example: In-context learning = task-solving via examples, no training needed.

- Extracts general factual knowledge, concepts and meanings from raw conversations
- Namespace: `/strategies/{memoryStrategyId}/actors/{actorId}`

#### User Preference Strategy

Captures individual preferences, interaction patterns, and personalized settings to enhance future experiences. Extracted memory example: User needs clear guidance on cloud storage account connection during onboarding.

- Extracts user behavior patterns from raw conversations
- Namespace: `/strategies/{memoryStrategyId}/actors/{actorId}`

```hcl
module "agentcore" {
  source  = "aws-ia/agentcore/aws"
  version = "0.0.3"

  # Create memory with built-in strategies
  create_memory = true
  memory_name = "my_memory"
  memory_description = "Memory with built-in strategies"
  memory_event_expiry_duration = 90

  # Add built-in memory strategies
  memory_strategies = [
    {
      summarization_memory_strategy = {
        name = "summary_strategy"
        description = "Built-in summarization memory strategy"
        namespaces = ["/strategies/{memoryStrategyId}/actors/{actorId}/sessions/{sessionId}"]
      }
    },
    {
      semantic_memory_strategy = {
        name = "semantic_strategy"
        description = "Built-in semantic memory strategy"
        namespaces = ["/strategies/{memoryStrategyId}/actors/{actorId}"]
      }
    },
    {
      user_preference_memory_strategy = {
        name = "preference_strategy"
        description = "Built-in user preference memory strategy"
        namespaces = ["/strategies/{memoryStrategyId}/actors/{actorId}"]
      }
    }
  ]
}
```

The name generated for each built in memory strategy follows this pattern:

- For Summarization: `summary_builtin_<suffix>`
- For Semantic: `semantic_builtin_<suffix>`
- For User Preferences: `preference_builtin_<suffix>`

Where the suffix is a 5 characters string ([a-z, A-Z, 0-9]).

#### LTM Memory Extraction Stategies

If you need long-term memory for context recall across sessions, you can setup memory extraction strategies to extract the relevant memory from the raw events.

Amazon Bedrock AgentCore Memory has different memory strategies for extracting and organizing information:

- **Summarization**: to summarize interactions to preserve critical context and key insights.
- **Semantic Memory**: to extract general factual knowledge, concepts and meanings from raw conversations using vector embeddings. This enables similarity-based retrieval of relevant facts and context.
- **User Preferences**: to extract user behavior patterns from raw conversations.

You can use built-in extraction strategies for quick setup, or create custom extraction strategies with specific models and prompt templates.

#### Memory with Built-in Strategies - Custom Namespace

With Long-Term Memory, organization is managed through Namespaces.

An `actor` refers to entity such as end users or agent/user combinations. For example, in a coding support chatbot, the actor is usually the developer asking questions. Using the actor ID helps the system know which user the memory belongs to, keeping each user's data separate and organized.

A `session` is usually a single conversation or interaction period between the user and the AI agent. It groups all related messages and events that happen during that conversation.

A `namespace` is used to logically group and organize long-term memories. It ensures data stays neat, separate, and secure.

With AgentCore Memory, you need to add a namespace when you define a memory strategy. This namespace helps define where the long-term memory will be logically grouped. Every time a new long-term memory is extracted using this memory strategy, it is saved under the namespace you set. This means that all long-term memories are scoped to their specific namespace, keeping them organized and preventing any mix-ups with other users or sessions. You should use a hierarchical format separated by forward slashes /. This helps keep memories organized clearly. As needed, you can choose to use the below pre-defined variables within braces in the namespace based on your applications' organization needs:

- `actorId` – Identifies who the long-term memory belongs to, such as a user
- `memoryStrategyId` – Shows which memory strategy is being used. This strategy identifier is auto-generated when you create a memory using CreateMemory operation.
- `sessionId` – Identifies which session or conversation the memory is from.

For example, if you define the following namespace as the input to your strategy:

```shell
/strategy/{memoryStrategyId}/actor/{actorId}/session/{sessionId}
```

After memory creation, this namespace might look like:

```shell
/strategy/summarization-93483043//actor/actor-9830m2w3/session/session-9330sds8
```

You can customize the namespace (where the memories are stored) by configuring the memory strategies in your Terraform configuration:

```hcl
module "agentcore" {
  source  = "aws-ia/agentcore/aws"
  version = "0.0.3"

  # Enable Agent Core Memory
  create_memory = true
  memory_name = "my_memory"
  memory_description = "Memory with built-in strategies"
  memory_event_expiry_duration = 90

  # Configure memory strategies with custom namespaces
  memory_strategies = [
    {
      user_preference_memory_strategy = {
        name = "CustomerPreferences"
        description = "User preference memory strategy"
        namespaces = ["support/customer/{actorId}/preferences"]
      }
    },
    {
      semantic_memory_strategy = {
        name = "CustomerSupportSemantic"
        description = "Semantic memory strategy"
        namespaces = ["support/customer/{actorId}/semantic"]
      }
    }
  ]
}
```

#### Custom Strategies (Built-in strategy with override)

Custom memory strategies let you tailor memory extraction and consolidation to your specific domain or use case. You can override the prompts for extracting and consolidating semantic, summary, or user preferences. You can also choose the model that you want to use for extraction and consolidation.

The custom prompts you create are appended to a non-editable system prompt.

Since a custom strategy requires you to invoke certain Foundation Models, you need a role with appropriate permissions. For that, you can:

- Use a custom role with the overly permissive `AmazonBedrockAgentCoreMemoryBedrockModelInferenceExecutionRolePolicy` managed policy.
- Use a custom role with your own custom policies.

#### Memory with Custom Execution Role

Keep in mind that memories that **do not** use custom strategies do not require a service role. A role is only created automatically when you use custom memory strategies that need to invoke foundation models. For standard built-in strategies (semantic, summary, user preference), no role is needed.

#### Policy Documents for Other Resources

The module also exposes IAM policy documents that you can use to grant memory permissions to other resources (like Lambda functions or EC2 instances):

```hcl
# Create a Lambda function that needs to write to memory
resource "aws_lambda_function" "memory_writer" {
  function_name = "memory-writer"
  # ... other Lambda configuration ...
}

# Create a policy for the Lambda using the provided policy document
resource "aws_iam_policy" "memory_write_policy" {
  name   = "memory-write-policy"
  policy = jsonencode(module.agentcore.memory_stm_write_policy)
}

# Attach the policy to the Lambda role
resource "aws_iam_role_policy_attachment" "memory_write_policy_attachment" {
  role       = aws_lambda_function.memory_writer.role
  policy_arn = aws_iam_policy.memory_write_policy.arn
}
```

Available policy documents include:

- `memory_stm_write_policy` - For STM write permissions
- `memory_read_policy` - For read permissions to both STM and LTM
- `memory_stm_read_policy` - For STM-only read permissions
- `memory_ltm_read_policy` - For LTM-only read permissions
- `memory_delete_policy` - For delete permissions to both STM and LTM
- `memory_stm_delete_policy` - For STM-only delete permissions
- `memory_ltm_delete_policy` - For LTM-only delete permissions
- `memory_admin_policy` - For control plane admin permissions
- `memory_full_access_policy` - For full access to all operations

### AgentCore Browser Custom

The Amazon Bedrock AgentCore Browser provides a secure, cloud-based browser that enables AI agents to interact with websites. It includes security features such as session isolation, built-in observability through live viewing, CloudTrail logging, and session replay capabilities.

Additional information about the browser tool can be found in the official [documentation](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/browser-tool.html).

#### Browser Network modes

The Browser construct supports the following network modes:

1. Public Network Mode - Default

- Allows internet access for web browsing and external API calls
- Suitable for scenarios where agents need to interact with publicly available websites
- Enables full web browsing capabilities
- VPC mode is not supported with this option

2. VPC (Virtual Private Cloud)

- Select whether to run the browser in a virtual private cloud (VPC).
- By configuring VPC connectivity, you enable secure access to private resources such as databases, internal APIs, and services within your VPC.

```hcl
module "agentcore" {
  source  = "aws-ia/agentcore/aws"
  version = "0.0.3"

  # Enable Agent Core Browser Custom
  create_browser = true
  browser_name = "MyBrowser"
  browser_description = "Custom browser for my Bedrock agent"
  browser_network_mode = "PUBLIC"  # PUBLIC or VPC

  # Optional: Enable recording to S3
  browser_recording_enabled = true
  browser_recording_config = {
    bucket = "my-browser-recordings-bucket"
    prefix = "recordings/"
  }

  # Optional: For VPC network mode
  # browser_network_configuration = {
  #   security_groups = ["enter_security_group"]
  #   subnets         = ["enter_subnet"]
  # }

  browser_tags = {
    Environment = "production"
    Project     = "ai-assistants"
  }
}
```

### AgentCore Gateway Target

The Amazon Bedrock AgentCore Gateway Target enables you to define the endpoints and configurations that a gateway can invoke, such as Lambda functions or MCP servers. Gateway targets allow agents to interact with external services through the Model Context Protocol (MCP).

```hcl
module "agentcore" {
  source  = "aws-ia/agentcore/aws"
  version = "0.0.3"

  # First, create a gateway
  create_gateway = true
  gateway_name = "MyGateway"

  # Then create a gateway target for Lambda
  create_gateway_target = true
  gateway_target_name = "MyLambdaTarget"
  gateway_target_description = "Lambda function target for processing requests"

  # Use the gateway's IAM role for authentication
  gateway_target_credential_provider_type = "GATEWAY_IAM_ROLE"

  # Configure the Lambda target
  gateway_target_type = "LAMBDA"
  gateway_target_lambda_config = {
    lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:my-function"
    tool_schema_type = "INLINE"
    inline_schema = {
      name        = "process_request"
      description = "Process incoming requests"

      input_schema = {
        type        = "object"
        description = "Request processing schema"
        properties = [
          {
            name        = "message"
            type        = "string"
            description = "Message to process"
            required    = true
          },
          {
            name = "options"
            type = "object"
            nested_properties = [
              {
                name = "priority"
                type = "string"
              }
            ]
          }
        ]
      }

      output_schema = {
        type = "object"
        properties = [
          {
            name     = "status"
            type     = "string"
            required = true
          },
          {
            name = "result"
            type = "string"
          }
        ]
      }
    }
  }
}
```

#### Gateway Target with API Key Authentication

```hcl
module "agentcore" {
  source  = "aws-ia/agentcore/aws"
  version = "0.0.3"

  # Create a gateway target with API Key authentication
  create_gateway_target = true
  gateway_target_name = "ApiKeyTarget"
  gateway_target_gateway_id = "your-gateway-id" # If using existing gateway

  gateway_target_credential_provider_type = "API_KEY"
  gateway_target_api_key_config = {
    provider_arn = "arn:aws:iam::123456789012:oidc-provider/example.com"
    credential_location = "HEADER"
    credential_parameter_name = "X-API-Key"
    credential_prefix = "Bearer"
  }

  # Configure Lambda target
  gateway_target_type = "LAMBDA"
  gateway_target_lambda_config = {
    lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:api-function"
    tool_schema_type = "INLINE"
    inline_schema = {
      name        = "api_tool"
      description = "External API integration tool"

      input_schema = {
        type = "string"
        description = "Simple string input for API calls"
      }
    }
  }
}
```

#### Gateway Target with MCP Server

```hcl
module "agentcore" {
  source  = "aws-ia/agentcore/aws"
  version = "0.0.3"

  # Create a gateway target for an MCP server
  create_gateway_target = true
  gateway_target_name = "MCPServerTarget"

  # Configure MCP Server target
  gateway_target_type = "MCP_SERVER"
  gateway_target_mcp_server_config = {
    endpoint = "https://mcp-server.example.com"
  }
}
```

### AgentCore Workload Identity

The Amazon Bedrock AgentCore Workload Identity enables you to manage identity configurations for resources such as AgentCore runtime and AgentCore gateway. Workload identities provide secure access management and OAuth2 integration capabilities for your Bedrock AI applications.

```hcl
module "agentcore" {
  source  = "aws-ia/agentcore/aws"
  version = "0.0.3"

  # Enable Workload Identity
  create_workload_identity = true
  workload_identity_name = "MyWorkloadIdentity"
  workload_identity_allowed_resource_oauth_2_return_urls = [
    "https://example.com/oauth2/callback",
    "https://api.example.com/auth/callback"
  ]

  # Optional: Add tags
  workload_identity_tags = {
    Environment = "production"
    Project     = "ai-assistants"
  }
}
```

### AgentCore Code Interpreter Custom

The Amazon Bedrock AgentCore Code Interpreter enables AI agents to write and execute code securely in sandbox environments, enhancing their accuracy and expanding their ability to solve complex end-to-end tasks. This is critical in Agentic AI applications where the agents may execute arbitrary code that can lead to data compromise or security risks. The AgentCore Code Interpreter tool provides secure code execution, which helps you avoid running into these issues.

For more information about code interpreter, please refer to the [official documentation](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/code-interpreter-tool.html).

#### Code Interpreter Network Modes

The Code Interpreter construct supports the following network modes:

1. Public Network Mode - Default

- Allows internet access for package installation and external API calls
- Suitable for development and testing environments
- Enables downloading Python packages from PyPI

2. Sandbox Network Mode

- Isolated network environment with no internet access
- Suitable for production environments with strict security requirements
- Only allows access to pre-installed packages and local resources

3. VPC (Virtual Private Cloud)

- Select whether to run the browser in a virtual private cloud (VPC).
- By configuring VPC connectivity, you enable secure access to private resources such as databases, internal APIs, and services within your VPC.

```hcl
module "agentcore" {
  source  = "aws-ia/agentcore/aws"
  version = "0.0.3"

  # Enable Agent Core Code Interpreter Custom
  create_code_interpreter = true
  code_interpreter_name = "MyCodeInterpreter"
  code_interpreter_description = "Custom code interpreter for my Bedrock agent"
  code_interpreter_network_mode = "SANDBOX"  # SANDBOX or VPC

  # Optional: For VPC network mode
  # code_interpreter_network_configuration = {
  #   security_groups = ["enter-sg"]
  #   subnets         = ["enter-subnet"]
  # }

  code_interpreter_tags = {
    Environment = "production"
    Project     = "ai-assistants"
  }
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

memory_tags = {
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
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.23.0 |
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | 1.65.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.13.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_bedrockagentcore_gateway_target.gateway_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_gateway_target) | resource |
| [aws_cognito_user.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user) | resource |
| [aws_cognito_user_pool.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_user_pool_client.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) | resource |
| [aws_cognito_user_pool_domain.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_domain) | resource |
| [aws_iam_policy.memory_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.memory_self_managed_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.browser_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.code_interpreter_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.gateway_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.memory_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.runtime_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.browser_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.code_interpreter_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.gateway_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.runtime_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.runtime_slr_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.memory_execution_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.memory_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.memory_self_managed_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_permission.cross_account_lambda_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [awscc_bedrockagentcore_browser_custom.agent_browser](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_browser_custom) | resource |
| [awscc_bedrockagentcore_code_interpreter_custom.agent_code_interpreter](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_code_interpreter_custom) | resource |
| [awscc_bedrockagentcore_gateway.agent_gateway](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_gateway) | resource |
| [awscc_bedrockagentcore_memory.agent_memory](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_memory) | resource |
| [awscc_bedrockagentcore_runtime.agent_runtime_code](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_runtime) | resource |
| [awscc_bedrockagentcore_runtime.agent_runtime_container](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_runtime) | resource |
| [awscc_bedrockagentcore_runtime_endpoint.agent_runtime_endpoint](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_runtime_endpoint) | resource |
| [awscc_bedrockagentcore_workload_identity.workload_identity](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_workload_identity) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.solution_prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [time_sleep.browser_iam_role_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.code_interpreter_iam_role_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.iam_role_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.memory_iam_role_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy.bedrock_memory_inference_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.service_linked_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apikey_credential_provider_arn"></a> [apikey\_credential\_provider\_arn](#input\_apikey\_credential\_provider\_arn) | ARN of the API key credential provider created with CreateApiKeyCredentialProvider. Required when enable\_apikey\_outbound\_auth is true. | `string` | `null` | no |
| <a name="input_apikey_secret_arn"></a> [apikey\_secret\_arn](#input\_apikey\_secret\_arn) | ARN of the AWS Secrets Manager secret containing the API key. Required when enable\_apikey\_outbound\_auth is true. | `string` | `null` | no |
| <a name="input_browser_description"></a> [browser\_description](#input\_browser\_description) | Description of the agent core browser. | `string` | `null` | no |
| <a name="input_browser_name"></a> [browser\_name](#input\_browser\_name) | The name of the agent core browser. Valid characters are a-z, A-Z, 0-9, \_ (underscore). The name must start with a letter and can be up to 48 characters long. | `string` | `"TerraformBedrockAgentCoreBrowser"` | no |
| <a name="input_browser_network_configuration"></a> [browser\_network\_configuration](#input\_browser\_network\_configuration) | VPC network configuration for the agent core browser. Required when browser\_network\_mode is set to 'VPC'. | <pre>object({<br/>    security_groups = optional(list(string))<br/>    subnets         = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_browser_network_mode"></a> [browser\_network\_mode](#input\_browser\_network\_mode) | Network mode configuration type for the agent core browser. Valid values: PUBLIC, VPC. | `string` | `"PUBLIC"` | no |
| <a name="input_browser_recording_config"></a> [browser\_recording\_config](#input\_browser\_recording\_config) | Configuration for browser session recording when enabled. Bucket name must follow S3 naming conventions (lowercase alphanumeric characters, dots, and hyphens), between 3 and 63 characters, starting and ending with alphanumeric character. | <pre>object({<br/>    bucket = string<br/>    prefix = string<br/>  })</pre> | `null` | no |
| <a name="input_browser_recording_enabled"></a> [browser\_recording\_enabled](#input\_browser\_recording\_enabled) | Whether to enable browser session recording to S3. | `bool` | `false` | no |
| <a name="input_browser_role_arn"></a> [browser\_role\_arn](#input\_browser\_role\_arn) | Optional external IAM role ARN for the Bedrock agent core browser. If empty, the module will create one internally. | `string` | `null` | no |
| <a name="input_browser_tags"></a> [browser\_tags](#input\_browser\_tags) | A map of tag keys and values for the agent core browser. Each tag key and value must be between 1 and 256 characters and can only include alphanumeric characters, spaces, and the following special characters: \_ . : / = + @ - | `map(string)` | `null` | no |
| <a name="input_code_interpreter_description"></a> [code\_interpreter\_description](#input\_code\_interpreter\_description) | Description of the agent core code interpreter. Valid characters are a-z, A-Z, 0-9, \_ (underscore), - (hyphen) and spaces. The description can have up to 200 characters. | `string` | `null` | no |
| <a name="input_code_interpreter_name"></a> [code\_interpreter\_name](#input\_code\_interpreter\_name) | The name of the agent core code interpreter. Valid characters are a-z, A-Z, 0-9, \_ (underscore). The name must start with a letter and can be up to 48 characters long. | `string` | `"TerraformBedrockAgentCoreCodeInterpreter"` | no |
| <a name="input_code_interpreter_network_configuration"></a> [code\_interpreter\_network\_configuration](#input\_code\_interpreter\_network\_configuration) | VPC network configuration for the agent core code interpreter. | <pre>object({<br/>    security_groups = optional(list(string))<br/>    subnets         = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_code_interpreter_network_mode"></a> [code\_interpreter\_network\_mode](#input\_code\_interpreter\_network\_mode) | Network mode configuration type for the agent core code interpreter. Valid values: SANDBOX, VPC. | `string` | `"SANDBOX"` | no |
| <a name="input_code_interpreter_role_arn"></a> [code\_interpreter\_role\_arn](#input\_code\_interpreter\_role\_arn) | Optional external IAM role ARN for the Bedrock agent core code interpreter. If empty, the module will create one internally. | `string` | `null` | no |
| <a name="input_code_interpreter_tags"></a> [code\_interpreter\_tags](#input\_code\_interpreter\_tags) | A map of tag keys and values for the agent core code interpreter. Each tag key and value must be between 1 and 256 characters and can only include alphanumeric characters, spaces, and the following special characters: \_ . : / = + @ - | `map(string)` | `null` | no |
| <a name="input_create_browser"></a> [create\_browser](#input\_create\_browser) | Whether or not to create an agent core browser custom. | `bool` | `false` | no |
| <a name="input_create_code_interpreter"></a> [create\_code\_interpreter](#input\_create\_code\_interpreter) | Whether or not to create an agent core code interpreter custom. | `bool` | `false` | no |
| <a name="input_create_gateway"></a> [create\_gateway](#input\_create\_gateway) | Whether or not to create an agent core gateway. | `bool` | `false` | no |
| <a name="input_create_gateway_target"></a> [create\_gateway\_target](#input\_create\_gateway\_target) | Whether or not to create a Bedrock agent core gateway target. | `bool` | `false` | no |
| <a name="input_create_memory"></a> [create\_memory](#input\_create\_memory) | Whether or not to create an agent core memory. | `bool` | `false` | no |
| <a name="input_create_runtime"></a> [create\_runtime](#input\_create\_runtime) | Whether or not to create an agent core runtime. | `bool` | `false` | no |
| <a name="input_create_runtime_endpoint"></a> [create\_runtime\_endpoint](#input\_create\_runtime\_endpoint) | Whether or not to create an agent core runtime endpoint. | `bool` | `false` | no |
| <a name="input_create_workload_identity"></a> [create\_workload\_identity](#input\_create\_workload\_identity) | Whether or not to create a Bedrock agent core workload identity. | `bool` | `false` | no |
| <a name="input_enable_apikey_outbound_auth"></a> [enable\_apikey\_outbound\_auth](#input\_enable\_apikey\_outbound\_auth) | Whether to enable outbound authorization with an API key for the gateway. | `bool` | `false` | no |
| <a name="input_enable_oauth_outbound_auth"></a> [enable\_oauth\_outbound\_auth](#input\_enable\_oauth\_outbound\_auth) | Whether to enable outbound authorization with an OAuth client for the gateway. | `bool` | `false` | no |
| <a name="input_gateway_allow_create_permissions"></a> [gateway\_allow\_create\_permissions](#input\_gateway\_allow\_create\_permissions) | Whether to allow create permissions for the gateway. | `bool` | `true` | no |
| <a name="input_gateway_allow_update_delete_permissions"></a> [gateway\_allow\_update\_delete\_permissions](#input\_gateway\_allow\_update\_delete\_permissions) | Whether to allow update and delete permissions for the gateway. | `bool` | `false` | no |
| <a name="input_gateway_authorizer_configuration"></a> [gateway\_authorizer\_configuration](#input\_gateway\_authorizer\_configuration) | Authorizer configuration for the agent core gateway. | <pre>object({<br/>    custom_jwt_authorizer = object({<br/>      allowed_audience = optional(list(string))<br/>      allowed_clients  = optional(list(string))<br/>      discovery_url    = string<br/>    })<br/>  })</pre> | `null` | no |
| <a name="input_gateway_authorizer_type"></a> [gateway\_authorizer\_type](#input\_gateway\_authorizer\_type) | The authorizer type for the gateway. Valid values: AWS\_IAM, CUSTOM\_JWT. | `string` | `"CUSTOM_JWT"` | no |
| <a name="input_gateway_cross_account_lambda_permissions"></a> [gateway\_cross\_account\_lambda\_permissions](#input\_gateway\_cross\_account\_lambda\_permissions) | Configuration for cross-account Lambda function access. Required only if Lambda functions are in different AWS accounts. | <pre>list(object({<br/>    lambda_function_arn      = string<br/>    gateway_service_role_arn = string<br/>  }))</pre> | `[]` | no |
| <a name="input_gateway_description"></a> [gateway\_description](#input\_gateway\_description) | Description of the agent core gateway. | `string` | `null` | no |
| <a name="input_gateway_exception_level"></a> [gateway\_exception\_level](#input\_gateway\_exception\_level) | Exception level for the gateway. Valid values: DEBUG, INFO, WARN, ERROR. | `string` | `null` | no |
| <a name="input_gateway_kms_key_arn"></a> [gateway\_kms\_key\_arn](#input\_gateway\_kms\_key\_arn) | The ARN of the KMS key used to encrypt the gateway. | `string` | `null` | no |
| <a name="input_gateway_lambda_function_arns"></a> [gateway\_lambda\_function\_arns](#input\_gateway\_lambda\_function\_arns) | List of Lambda function ARNs that the gateway service role should be able to invoke. Required when using Lambda targets. | `list(string)` | `[]` | no |
| <a name="input_gateway_name"></a> [gateway\_name](#input\_gateway\_name) | The name of the agent core gateway. | `string` | `"TerraformBedrockAgentCoreGateway"` | no |
| <a name="input_gateway_protocol_configuration"></a> [gateway\_protocol\_configuration](#input\_gateway\_protocol\_configuration) | Protocol configuration for the agent core gateway. | <pre>object({<br/>    mcp = object({<br/>      instructions       = optional(string)<br/>      search_type        = optional(string)<br/>      supported_versions = optional(list(string))<br/>    })<br/>  })</pre> | `null` | no |
| <a name="input_gateway_protocol_type"></a> [gateway\_protocol\_type](#input\_gateway\_protocol\_type) | The protocol type for the gateway. Valid value: MCP. | `string` | `"MCP"` | no |
| <a name="input_gateway_role_arn"></a> [gateway\_role\_arn](#input\_gateway\_role\_arn) | Optional external IAM role ARN for the Bedrock agent core gateway. If empty, the module will create one internally. | `string` | `null` | no |
| <a name="input_gateway_tags"></a> [gateway\_tags](#input\_gateway\_tags) | A map of tag keys and values for the agent core gateway. | `map(string)` | `null` | no |
| <a name="input_gateway_target_api_key_config"></a> [gateway\_target\_api\_key\_config](#input\_gateway\_target\_api\_key\_config) | Configuration for API key authentication for the gateway target. | <pre>object({<br/>    provider_arn              = string<br/>    credential_location       = optional(string)<br/>    credential_parameter_name = optional(string)<br/>    credential_prefix         = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_gateway_target_credential_provider_type"></a> [gateway\_target\_credential\_provider\_type](#input\_gateway\_target\_credential\_provider\_type) | Type of credential provider to use for the gateway target. Valid values: GATEWAY\_IAM\_ROLE, API\_KEY, OAUTH. | `string` | `"GATEWAY_IAM_ROLE"` | no |
| <a name="input_gateway_target_description"></a> [gateway\_target\_description](#input\_gateway\_target\_description) | Description of the gateway target. | `string` | `null` | no |
| <a name="input_gateway_target_gateway_id"></a> [gateway\_target\_gateway\_id](#input\_gateway\_target\_gateway\_id) | Identifier of the gateway that this target belongs to. If not provided, it will use the ID of the gateway created by this module. | `string` | `null` | no |
| <a name="input_gateway_target_lambda_config"></a> [gateway\_target\_lambda\_config](#input\_gateway\_target\_lambda\_config) | Configuration for Lambda function target. | <pre>object({<br/>    lambda_arn       = string<br/>    tool_schema_type = string # INLINE or S3<br/>    inline_schema = optional(object({<br/>      name        = string<br/>      description = string<br/>      input_schema = object({<br/>        type        = string<br/>        description = optional(string)<br/>        properties = optional(list(object({<br/>          name        = string<br/>          type        = string<br/>          description = optional(string)<br/>          required    = optional(bool, false)<br/>          nested_properties = optional(list(object({<br/>            name        = string<br/>            type        = string<br/>            description = optional(string)<br/>            required    = optional(bool)<br/>          })))<br/>          items = optional(object({<br/>            type        = string<br/>            description = optional(string)<br/>          }))<br/>        })))<br/>        items = optional(object({<br/>          type        = string<br/>          description = optional(string)<br/>        }))<br/>      })<br/>      output_schema = optional(object({<br/>        type        = string<br/>        description = optional(string)<br/>        properties = optional(list(object({<br/>          name        = string<br/>          type        = string<br/>          description = optional(string)<br/>          required    = optional(bool)<br/>        })))<br/>        items = optional(object({<br/>          type        = string<br/>          description = optional(string)<br/>        }))<br/>      }))<br/>    }))<br/>    s3_schema = optional(object({<br/>      uri                     = string<br/>      bucket_owner_account_id = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_gateway_target_mcp_server_config"></a> [gateway\_target\_mcp\_server\_config](#input\_gateway\_target\_mcp\_server\_config) | Configuration for MCP server target. | <pre>object({<br/>    endpoint = string<br/>  })</pre> | `null` | no |
| <a name="input_gateway_target_name"></a> [gateway\_target\_name](#input\_gateway\_target\_name) | The name of the gateway target. | `string` | `"TerraformBedrockAgentCoreGatewayTarget"` | no |
| <a name="input_gateway_target_oauth_config"></a> [gateway\_target\_oauth\_config](#input\_gateway\_target\_oauth\_config) | Configuration for OAuth authentication for the gateway target. | <pre>object({<br/>    provider_arn      = string<br/>    scopes            = optional(list(string))<br/>    custom_parameters = optional(map(string))<br/>  })</pre> | `null` | no |
| <a name="input_gateway_target_type"></a> [gateway\_target\_type](#input\_gateway\_target\_type) | Type of target to create. Valid values: LAMBDA, MCP\_SERVER. | `string` | `"LAMBDA"` | no |
| <a name="input_memory_description"></a> [memory\_description](#input\_memory\_description) | Description of the agent core memory. | `string` | `null` | no |
| <a name="input_memory_encryption_key_arn"></a> [memory\_encryption\_key\_arn](#input\_memory\_encryption\_key\_arn) | The ARN of the KMS key used to encrypt the memory. | `string` | `null` | no |
| <a name="input_memory_event_expiry_duration"></a> [memory\_event\_expiry\_duration](#input\_memory\_event\_expiry\_duration) | Duration in days until memory events expire. | `number` | `90` | no |
| <a name="input_memory_execution_role_arn"></a> [memory\_execution\_role\_arn](#input\_memory\_execution\_role\_arn) | Optional IAM role ARN for the Bedrock agent core memory. | `string` | `null` | no |
| <a name="input_memory_name"></a> [memory\_name](#input\_memory\_name) | The name of the agent core memory. | `string` | `"TerraformBedrockAgentCoreMemory"` | no |
| <a name="input_memory_strategies"></a> [memory\_strategies](#input\_memory\_strategies) | List of memory strategies attached to this memory. | <pre>list(object({<br/>    semantic_memory_strategy = optional(object({<br/>      name        = optional(string)<br/>      description = optional(string)<br/>      namespaces  = optional(list(string))<br/>    }))<br/>    summary_memory_strategy = optional(object({<br/>      name        = optional(string)<br/>      description = optional(string)<br/>      namespaces  = optional(list(string))<br/>    }))<br/>    user_preference_memory_strategy = optional(object({<br/>      name        = optional(string)<br/>      description = optional(string)<br/>      namespaces  = optional(list(string))<br/>    }))<br/>    custom_memory_strategy = optional(object({<br/>      name        = optional(string)<br/>      description = optional(string)<br/>      namespaces  = optional(list(string))<br/>      configuration = optional(object({<br/>        self_managed_configuration = optional(object({<br/>          historical_context_window_size = optional(number, 4) # Default to 4 messages<br/>          invocation_configuration = object({<br/>            # Both fields are required when a self-managed configuration is used<br/>            payload_delivery_bucket_name = string<br/>            topic_arn                    = string<br/>          })<br/>          trigger_conditions = optional(list(object({<br/>            message_based_trigger = optional(object({<br/>              message_count = optional(number, 1) # Default to 1 message<br/>            }))<br/>            time_based_trigger = optional(object({<br/>              idle_session_timeout = optional(number, 10) # Default to 10 seconds<br/>            }))<br/>            token_based_trigger = optional(object({<br/>              token_count = optional(number, 100) # Default to 100 tokens<br/>            }))<br/>          })))<br/>        }))<br/>        semantic_override = optional(object({<br/>          consolidation = optional(object({<br/>            append_to_prompt = optional(string)<br/>            model_id         = optional(string)<br/>          }))<br/>          extraction = optional(object({<br/>            append_to_prompt = optional(string)<br/>            model_id         = optional(string)<br/>          }))<br/>        }))<br/>        summary_override = optional(object({<br/>          consolidation = optional(object({<br/>            append_to_prompt = optional(string)<br/>            model_id         = optional(string)<br/>          }))<br/>        }))<br/>        user_preference_override = optional(object({<br/>          consolidation = optional(object({<br/>            append_to_prompt = optional(string)<br/>            model_id         = optional(string)<br/>          }))<br/>          extraction = optional(object({<br/>            append_to_prompt = optional(string)<br/>            model_id         = optional(string)<br/>          }))<br/>        }))<br/>      }))<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_memory_tags"></a> [memory\_tags](#input\_memory\_tags) | A map of tag keys and values for the agent core memory. | `map(string)` | `null` | no |
| <a name="input_oauth_credential_provider_arn"></a> [oauth\_credential\_provider\_arn](#input\_oauth\_credential\_provider\_arn) | ARN of the OAuth credential provider created with CreateOauth2CredentialProvider. Required when enable\_oauth\_outbound\_auth is true. | `string` | `null` | no |
| <a name="input_oauth_secret_arn"></a> [oauth\_secret\_arn](#input\_oauth\_secret\_arn) | ARN of the AWS Secrets Manager secret containing the OAuth client credentials. Required when enable\_oauth\_outbound\_auth is true. | `string` | `null` | no |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | The ARN of the IAM permission boundary for the role. | `string` | `null` | no |
| <a name="input_runtime_artifact_type"></a> [runtime\_artifact\_type](#input\_runtime\_artifact\_type) | The type of artifact to use for the agent core runtime. Valid values: container, code. | `string` | `"container"` | no |
| <a name="input_runtime_authorizer_configuration"></a> [runtime\_authorizer\_configuration](#input\_runtime\_authorizer\_configuration) | Authorizer configuration for the agent core runtime. | <pre>object({<br/>    custom_jwt_authorizer = object({<br/>      allowed_audience = optional(list(string))<br/>      allowed_clients  = optional(list(string))<br/>      discovery_url    = string<br/>    })<br/>  })</pre> | `null` | no |
| <a name="input_runtime_code_entry_point"></a> [runtime\_code\_entry\_point](#input\_runtime\_code\_entry\_point) | Entry point for the code runtime. Required when runtime\_artifact\_type is set to 'code'. | `list(string)` | `null` | no |
| <a name="input_runtime_code_runtime_type"></a> [runtime\_code\_runtime\_type](#input\_runtime\_code\_runtime\_type) | Runtime type for the code. Required when runtime\_artifact\_type is set to 'code'. Valid values: PYTHON\_3\_10, PYTHON\_3\_11, PYTHON\_3\_12, PYTHON\_3\_13 | `string` | `null` | no |
| <a name="input_runtime_code_s3_bucket"></a> [runtime\_code\_s3\_bucket](#input\_runtime\_code\_s3\_bucket) | S3 bucket containing the code package for the agent core runtime. Required when runtime\_artifact\_type is set to 'code'. | `string` | `null` | no |
| <a name="input_runtime_code_s3_prefix"></a> [runtime\_code\_s3\_prefix](#input\_runtime\_code\_s3\_prefix) | S3 prefix (key) for the code package. Required when runtime\_artifact\_type is set to 'code'. | `string` | `null` | no |
| <a name="input_runtime_code_s3_version_id"></a> [runtime\_code\_s3\_version\_id](#input\_runtime\_code\_s3\_version\_id) | S3 version ID of the code package. Optional when runtime\_artifact\_type is set to 'code'. | `string` | `null` | no |
| <a name="input_runtime_container_uri"></a> [runtime\_container\_uri](#input\_runtime\_container\_uri) | The ECR URI of the container for the agent core runtime. Required when runtime\_artifact\_type is set to 'container'. | `string` | `null` | no |
| <a name="input_runtime_description"></a> [runtime\_description](#input\_runtime\_description) | Description of the agent runtime. | `string` | `null` | no |
| <a name="input_runtime_endpoint_agent_runtime_id"></a> [runtime\_endpoint\_agent\_runtime\_id](#input\_runtime\_endpoint\_agent\_runtime\_id) | The ID of the agent core runtime associated with the endpoint. If not provided, it will use the ID of the agent runtime created by this module. | `string` | `null` | no |
| <a name="input_runtime_endpoint_description"></a> [runtime\_endpoint\_description](#input\_runtime\_endpoint\_description) | Description of the agent core runtime endpoint. | `string` | `null` | no |
| <a name="input_runtime_endpoint_name"></a> [runtime\_endpoint\_name](#input\_runtime\_endpoint\_name) | The name of the agent core runtime endpoint. | `string` | `"TerraformBedrockAgentCoreRuntimeEndpoint"` | no |
| <a name="input_runtime_endpoint_tags"></a> [runtime\_endpoint\_tags](#input\_runtime\_endpoint\_tags) | A map of tag keys and values for the agent core runtime endpoint. | `map(string)` | `null` | no |
| <a name="input_runtime_environment_variables"></a> [runtime\_environment\_variables](#input\_runtime\_environment\_variables) | Environment variables for the agent core runtime. | `map(string)` | `null` | no |
| <a name="input_runtime_lifecycle_configuration"></a> [runtime\_lifecycle\_configuration](#input\_runtime\_lifecycle\_configuration) | Lifecycle configuration for managing runtime sessions. | <pre>object({<br/>    idle_runtime_session_timeout = optional(number)<br/>    max_lifetime                 = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_runtime_name"></a> [runtime\_name](#input\_runtime\_name) | The name of the agent core runtime. | `string` | `"TerraformBedrockAgentCoreRuntime"` | no |
| <a name="input_runtime_network_configuration"></a> [runtime\_network\_configuration](#input\_runtime\_network\_configuration) | VPC network configuration for the agent core runtime. | <pre>object({<br/>    security_groups = optional(list(string))<br/>    subnets         = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_runtime_network_mode"></a> [runtime\_network\_mode](#input\_runtime\_network\_mode) | Network mode configuration type for the agent core runtime. Valid values: PUBLIC, VPC. | `string` | `"PUBLIC"` | no |
| <a name="input_runtime_protocol_configuration"></a> [runtime\_protocol\_configuration](#input\_runtime\_protocol\_configuration) | Protocol configuration for the agent core runtime. | `string` | `null` | no |
| <a name="input_runtime_request_header_configuration"></a> [runtime\_request\_header\_configuration](#input\_runtime\_request\_header\_configuration) | Configuration for HTTP request headers. | <pre>object({<br/>    request_header_allowlist = optional(set(string))<br/>  })</pre> | `null` | no |
| <a name="input_runtime_role_arn"></a> [runtime\_role\_arn](#input\_runtime\_role\_arn) | Optional external IAM role ARN for the Bedrock agent core runtime. If empty, the module will create one internally. | `string` | `null` | no |
| <a name="input_runtime_tags"></a> [runtime\_tags](#input\_runtime\_tags) | A map of tag keys and values for the agent core runtime. | `map(string)` | `null` | no |
| <a name="input_user_pool_admin_email"></a> [user\_pool\_admin\_email](#input\_user\_pool\_admin\_email) | Email address for the admin user. | `string` | `"admin@example.com"` | no |
| <a name="input_user_pool_allowed_clients"></a> [user\_pool\_allowed\_clients](#input\_user\_pool\_allowed\_clients) | List of allowed clients for the Cognito User Pool JWT authorizer. | `list(string)` | `[]` | no |
| <a name="input_user_pool_callback_urls"></a> [user\_pool\_callback\_urls](#input\_user\_pool\_callback\_urls) | List of allowed callback URLs for the Cognito User Pool client. | `list(string)` | <pre>[<br/>  "http://localhost:3000"<br/>]</pre> | no |
| <a name="input_user_pool_create_admin"></a> [user\_pool\_create\_admin](#input\_user\_pool\_create\_admin) | Whether to create an admin user in the Cognito User Pool. | `bool` | `false` | no |
| <a name="input_user_pool_logout_urls"></a> [user\_pool\_logout\_urls](#input\_user\_pool\_logout\_urls) | List of allowed logout URLs for the Cognito User Pool client. | `list(string)` | <pre>[<br/>  "http://localhost:3000"<br/>]</pre> | no |
| <a name="input_user_pool_mfa_configuration"></a> [user\_pool\_mfa\_configuration](#input\_user\_pool\_mfa\_configuration) | MFA configuration for the Cognito User Pool. Valid values: OFF, OPTIONAL, REQUIRED. | `string` | `"OFF"` | no |
| <a name="input_user_pool_name"></a> [user\_pool\_name](#input\_user\_pool\_name) | The name of the Cognito User Pool to create when JWT auth info is not provided. | `string` | `"AgentCoreUserPool"` | no |
| <a name="input_user_pool_password_policy"></a> [user\_pool\_password\_policy](#input\_user\_pool\_password\_policy) | Password policy for the Cognito User Pool. | <pre>object({<br/>    minimum_length    = optional(number, 8)<br/>    require_lowercase = optional(bool, true)<br/>    require_numbers   = optional(bool, true)<br/>    require_symbols   = optional(bool, true)<br/>    require_uppercase = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_user_pool_refresh_token_validity_days"></a> [user\_pool\_refresh\_token\_validity\_days](#input\_user\_pool\_refresh\_token\_validity\_days) | Number of days that refresh tokens are valid for. | `number` | `30` | no |
| <a name="input_user_pool_tags"></a> [user\_pool\_tags](#input\_user\_pool\_tags) | A map of tag keys and values for the Cognito User Pool. | `map(string)` | `null` | no |
| <a name="input_user_pool_token_validity_hours"></a> [user\_pool\_token\_validity\_hours](#input\_user\_pool\_token\_validity\_hours) | Number of hours that ID and access tokens are valid for. | `number` | `24` | no |
| <a name="input_workload_identity_allowed_resource_oauth_2_return_urls"></a> [workload\_identity\_allowed\_resource\_oauth\_2\_return\_urls](#input\_workload\_identity\_allowed\_resource\_oauth\_2\_return\_urls) | The list of allowed OAuth2 return URLs for resources associated with this workload identity. | `list(string)` | `null` | no |
| <a name="input_workload_identity_name"></a> [workload\_identity\_name](#input\_workload\_identity\_name) | The name of the workload identity. | `string` | `"TerraformBedrockAgentCoreWorkloadIdentity"` | no |
| <a name="input_workload_identity_tags"></a> [workload\_identity\_tags](#input\_workload\_identity\_tags) | A map of tag keys and values for the workload identity. | `map(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_agent_browser_arn"></a> [agent\_browser\_arn](#output\_agent\_browser\_arn) | ARN of the created Bedrock AgentCore Browser Custom |
| <a name="output_agent_browser_created_at"></a> [agent\_browser\_created\_at](#output\_agent\_browser\_created\_at) | Creation timestamp of the created Bedrock AgentCore Browser Custom |
| <a name="output_agent_browser_failure_reason"></a> [agent\_browser\_failure\_reason](#output\_agent\_browser\_failure\_reason) | Failure reason if the Bedrock AgentCore Browser Custom failed |
| <a name="output_agent_browser_id"></a> [agent\_browser\_id](#output\_agent\_browser\_id) | ID of the created Bedrock AgentCore Browser Custom |
| <a name="output_agent_browser_last_updated_at"></a> [agent\_browser\_last\_updated\_at](#output\_agent\_browser\_last\_updated\_at) | Last update timestamp of the created Bedrock AgentCore Browser Custom |
| <a name="output_agent_browser_status"></a> [agent\_browser\_status](#output\_agent\_browser\_status) | Status of the created Bedrock AgentCore Browser Custom |
| <a name="output_agent_code_interpreter_arn"></a> [agent\_code\_interpreter\_arn](#output\_agent\_code\_interpreter\_arn) | ARN of the created Bedrock AgentCore Code Interpreter Custom |
| <a name="output_agent_code_interpreter_created_at"></a> [agent\_code\_interpreter\_created\_at](#output\_agent\_code\_interpreter\_created\_at) | Creation timestamp of the created Bedrock AgentCore Code Interpreter Custom |
| <a name="output_agent_code_interpreter_failure_reason"></a> [agent\_code\_interpreter\_failure\_reason](#output\_agent\_code\_interpreter\_failure\_reason) | Failure reason if the Bedrock AgentCore Code Interpreter Custom failed |
| <a name="output_agent_code_interpreter_id"></a> [agent\_code\_interpreter\_id](#output\_agent\_code\_interpreter\_id) | ID of the created Bedrock AgentCore Code Interpreter Custom |
| <a name="output_agent_code_interpreter_last_updated_at"></a> [agent\_code\_interpreter\_last\_updated\_at](#output\_agent\_code\_interpreter\_last\_updated\_at) | Last update timestamp of the created Bedrock AgentCore Code Interpreter Custom |
| <a name="output_agent_code_interpreter_status"></a> [agent\_code\_interpreter\_status](#output\_agent\_code\_interpreter\_status) | Status of the created Bedrock AgentCore Code Interpreter Custom |
| <a name="output_agent_gateway_arn"></a> [agent\_gateway\_arn](#output\_agent\_gateway\_arn) | ARN of the created Bedrock AgentCore Gateway |
| <a name="output_agent_gateway_id"></a> [agent\_gateway\_id](#output\_agent\_gateway\_id) | ID of the created Bedrock AgentCore Gateway |
| <a name="output_agent_gateway_status"></a> [agent\_gateway\_status](#output\_agent\_gateway\_status) | Status of the created Bedrock AgentCore Gateway |
| <a name="output_agent_gateway_status_reasons"></a> [agent\_gateway\_status\_reasons](#output\_agent\_gateway\_status\_reasons) | Status reasons of the created Bedrock AgentCore Gateway |
| <a name="output_agent_gateway_url"></a> [agent\_gateway\_url](#output\_agent\_gateway\_url) | URL of the created Bedrock AgentCore Gateway |
| <a name="output_agent_gateway_workload_identity_details"></a> [agent\_gateway\_workload\_identity\_details](#output\_agent\_gateway\_workload\_identity\_details) | Workload identity details of the created Bedrock AgentCore Gateway |
| <a name="output_agent_memory_arn"></a> [agent\_memory\_arn](#output\_agent\_memory\_arn) | ARN of the created Bedrock AgentCore Memory |
| <a name="output_agent_memory_created_at"></a> [agent\_memory\_created\_at](#output\_agent\_memory\_created\_at) | Creation timestamp of the created Bedrock AgentCore Memory |
| <a name="output_agent_memory_id"></a> [agent\_memory\_id](#output\_agent\_memory\_id) | ID of the created Bedrock AgentCore Memory |
| <a name="output_agent_memory_status"></a> [agent\_memory\_status](#output\_agent\_memory\_status) | Status of the created Bedrock AgentCore Memory |
| <a name="output_agent_memory_updated_at"></a> [agent\_memory\_updated\_at](#output\_agent\_memory\_updated\_at) | Last update timestamp of the created Bedrock AgentCore Memory |
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
| <a name="output_browser_admin_permissions"></a> [browser\_admin\_permissions](#output\_browser\_admin\_permissions) | IAM permissions for browser administration operations |
| <a name="output_browser_admin_policy"></a> [browser\_admin\_policy](#output\_browser\_admin\_policy) | Policy document for browser administration |
| <a name="output_browser_full_access_permissions"></a> [browser\_full\_access\_permissions](#output\_browser\_full\_access\_permissions) | Full access IAM permissions for all browser operations |
| <a name="output_browser_full_access_policy"></a> [browser\_full\_access\_policy](#output\_browser\_full\_access\_policy) | Policy document for granting full access to Bedrock AgentCore Browser operations |
| <a name="output_browser_list_permissions"></a> [browser\_list\_permissions](#output\_browser\_list\_permissions) | IAM permissions for listing browser resources |
| <a name="output_browser_list_policy"></a> [browser\_list\_policy](#output\_browser\_list\_policy) | Policy document for listing browser resources |
| <a name="output_browser_read_permissions"></a> [browser\_read\_permissions](#output\_browser\_read\_permissions) | IAM permissions for reading browser information |
| <a name="output_browser_read_policy"></a> [browser\_read\_policy](#output\_browser\_read\_policy) | Policy document for reading browser information |
| <a name="output_browser_role_arn"></a> [browser\_role\_arn](#output\_browser\_role\_arn) | ARN of the IAM role created for the Bedrock AgentCore Browser Custom |
| <a name="output_browser_role_name"></a> [browser\_role\_name](#output\_browser\_role\_name) | Name of the IAM role created for the Bedrock AgentCore Browser Custom |
| <a name="output_browser_session_permissions"></a> [browser\_session\_permissions](#output\_browser\_session\_permissions) | IAM permissions for managing browser sessions |
| <a name="output_browser_session_policy"></a> [browser\_session\_policy](#output\_browser\_session\_policy) | Policy document for browser session management |
| <a name="output_browser_stream_permissions"></a> [browser\_stream\_permissions](#output\_browser\_stream\_permissions) | IAM permissions for browser streaming operations |
| <a name="output_browser_stream_policy"></a> [browser\_stream\_policy](#output\_browser\_stream\_policy) | Policy document for browser streaming operations |
| <a name="output_browser_use_permissions"></a> [browser\_use\_permissions](#output\_browser\_use\_permissions) | IAM permissions for using browser functionality |
| <a name="output_browser_use_policy"></a> [browser\_use\_policy](#output\_browser\_use\_policy) | Policy document for using browser functionality |
| <a name="output_code_interpreter_admin_permissions"></a> [code\_interpreter\_admin\_permissions](#output\_code\_interpreter\_admin\_permissions) | IAM permissions for code interpreter administration operations |
| <a name="output_code_interpreter_admin_policy"></a> [code\_interpreter\_admin\_policy](#output\_code\_interpreter\_admin\_policy) | Policy document for code interpreter administration |
| <a name="output_code_interpreter_full_access_permissions"></a> [code\_interpreter\_full\_access\_permissions](#output\_code\_interpreter\_full\_access\_permissions) | Full access IAM permissions for all code interpreter operations |
| <a name="output_code_interpreter_full_access_policy"></a> [code\_interpreter\_full\_access\_policy](#output\_code\_interpreter\_full\_access\_policy) | Policy document for granting full access to Bedrock AgentCore Code Interpreter operations |
| <a name="output_code_interpreter_invoke_permissions"></a> [code\_interpreter\_invoke\_permissions](#output\_code\_interpreter\_invoke\_permissions) | IAM permissions for invoking code interpreter |
| <a name="output_code_interpreter_invoke_policy"></a> [code\_interpreter\_invoke\_policy](#output\_code\_interpreter\_invoke\_policy) | Policy document for code interpreter invocation operations |
| <a name="output_code_interpreter_list_permissions"></a> [code\_interpreter\_list\_permissions](#output\_code\_interpreter\_list\_permissions) | IAM permissions for listing code interpreter resources |
| <a name="output_code_interpreter_list_policy"></a> [code\_interpreter\_list\_policy](#output\_code\_interpreter\_list\_policy) | Policy document for listing code interpreter resources |
| <a name="output_code_interpreter_read_permissions"></a> [code\_interpreter\_read\_permissions](#output\_code\_interpreter\_read\_permissions) | IAM permissions for reading code interpreter information |
| <a name="output_code_interpreter_read_policy"></a> [code\_interpreter\_read\_policy](#output\_code\_interpreter\_read\_policy) | Policy document for reading code interpreter information |
| <a name="output_code_interpreter_role_arn"></a> [code\_interpreter\_role\_arn](#output\_code\_interpreter\_role\_arn) | ARN of the IAM role created for the Bedrock AgentCore Code Interpreter Custom |
| <a name="output_code_interpreter_role_name"></a> [code\_interpreter\_role\_name](#output\_code\_interpreter\_role\_name) | Name of the IAM role created for the Bedrock AgentCore Code Interpreter Custom |
| <a name="output_code_interpreter_session_permissions"></a> [code\_interpreter\_session\_permissions](#output\_code\_interpreter\_session\_permissions) | IAM permissions for managing code interpreter sessions |
| <a name="output_code_interpreter_session_policy"></a> [code\_interpreter\_session\_policy](#output\_code\_interpreter\_session\_policy) | Policy document for code interpreter session management |
| <a name="output_code_interpreter_use_permissions"></a> [code\_interpreter\_use\_permissions](#output\_code\_interpreter\_use\_permissions) | IAM permissions for using code interpreter functionality |
| <a name="output_code_interpreter_use_policy"></a> [code\_interpreter\_use\_policy](#output\_code\_interpreter\_use\_policy) | Policy document for using code interpreter functionality |
| <a name="output_cognito_discovery_url"></a> [cognito\_discovery\_url](#output\_cognito\_discovery\_url) | OpenID Connect discovery URL for the Cognito User Pool |
| <a name="output_cognito_domain"></a> [cognito\_domain](#output\_cognito\_domain) | Domain of the Cognito User Pool |
| <a name="output_gateway_role_arn"></a> [gateway\_role\_arn](#output\_gateway\_role\_arn) | ARN of the IAM role created for the Bedrock AgentCore Gateway |
| <a name="output_gateway_role_name"></a> [gateway\_role\_name](#output\_gateway\_role\_name) | Name of the IAM role created for the Bedrock AgentCore Gateway |
| <a name="output_gateway_target_gateway_id"></a> [gateway\_target\_gateway\_id](#output\_gateway\_target\_gateway\_id) | ID of the gateway that this target belongs to |
| <a name="output_gateway_target_id"></a> [gateway\_target\_id](#output\_gateway\_target\_id) | ID of the created Bedrock AgentCore Gateway Target |
| <a name="output_gateway_target_name"></a> [gateway\_target\_name](#output\_gateway\_target\_name) | Name of the created Bedrock AgentCore Gateway Target |
| <a name="output_memory_admin_permissions"></a> [memory\_admin\_permissions](#output\_memory\_admin\_permissions) | IAM permissions for memory administration operations |
| <a name="output_memory_admin_policy"></a> [memory\_admin\_policy](#output\_memory\_admin\_policy) | Policy document for granting control plane admin permissions |
| <a name="output_memory_delete_permissions"></a> [memory\_delete\_permissions](#output\_memory\_delete\_permissions) | Combined IAM permissions for deleting from both Short-Term Memory (STM) and Long-Term Memory (LTM) |
| <a name="output_memory_delete_policy"></a> [memory\_delete\_policy](#output\_memory\_delete\_policy) | Policy document for granting delete permissions to both STM and LTM |
| <a name="output_memory_full_access_permissions"></a> [memory\_full\_access\_permissions](#output\_memory\_full\_access\_permissions) | Full access IAM permissions for all memory operations |
| <a name="output_memory_full_access_policy"></a> [memory\_full\_access\_policy](#output\_memory\_full\_access\_policy) | Policy document for granting full access to all memory operations |
| <a name="output_memory_kms_policy_arn"></a> [memory\_kms\_policy\_arn](#output\_memory\_kms\_policy\_arn) | ARN of the KMS policy for memory encryption (only available when KMS is provided) |
| <a name="output_memory_ltm_delete_permissions"></a> [memory\_ltm\_delete\_permissions](#output\_memory\_ltm\_delete\_permissions) | IAM permissions for deleting from Long-Term Memory (LTM) |
| <a name="output_memory_ltm_delete_policy"></a> [memory\_ltm\_delete\_policy](#output\_memory\_ltm\_delete\_policy) | Policy document for granting LTM delete permissions only |
| <a name="output_memory_ltm_read_permissions"></a> [memory\_ltm\_read\_permissions](#output\_memory\_ltm\_read\_permissions) | IAM permissions for reading from Long-Term Memory (LTM) |
| <a name="output_memory_ltm_read_policy"></a> [memory\_ltm\_read\_policy](#output\_memory\_ltm\_read\_policy) | Policy document for granting LTM read permissions only |
| <a name="output_memory_read_permissions"></a> [memory\_read\_permissions](#output\_memory\_read\_permissions) | Combined IAM permissions for reading from both Short-Term Memory (STM) and Long-Term Memory (LTM) |
| <a name="output_memory_read_policy"></a> [memory\_read\_policy](#output\_memory\_read\_policy) | Policy document for granting read permissions to both STM and LTM |
| <a name="output_memory_role_arn"></a> [memory\_role\_arn](#output\_memory\_role\_arn) | ARN of the IAM role created for the Bedrock AgentCore Memory |
| <a name="output_memory_role_name"></a> [memory\_role\_name](#output\_memory\_role\_name) | Name of the IAM role created for the Bedrock AgentCore Memory |
| <a name="output_memory_stm_delete_permissions"></a> [memory\_stm\_delete\_permissions](#output\_memory\_stm\_delete\_permissions) | IAM permissions for deleting from Short-Term Memory (STM) |
| <a name="output_memory_stm_delete_policy"></a> [memory\_stm\_delete\_policy](#output\_memory\_stm\_delete\_policy) | Policy document for granting STM delete permissions only |
| <a name="output_memory_stm_read_permissions"></a> [memory\_stm\_read\_permissions](#output\_memory\_stm\_read\_permissions) | IAM permissions for reading from Short-Term Memory (STM) |
| <a name="output_memory_stm_read_policy"></a> [memory\_stm\_read\_policy](#output\_memory\_stm\_read\_policy) | Policy document for granting STM read permissions only |
| <a name="output_memory_stm_write_permissions"></a> [memory\_stm\_write\_permissions](#output\_memory\_stm\_write\_permissions) | IAM permissions for writing to Short-Term Memory (STM) |
| <a name="output_memory_stm_write_policy"></a> [memory\_stm\_write\_policy](#output\_memory\_stm\_write\_policy) | Policy document for granting Short-Term Memory (STM) write permissions |
| <a name="output_runtime_role_arn"></a> [runtime\_role\_arn](#output\_runtime\_role\_arn) | ARN of the IAM role created for the Bedrock AgentCore Runtime |
| <a name="output_runtime_role_name"></a> [runtime\_role\_name](#output\_runtime\_role\_name) | Name of the IAM role created for the Bedrock AgentCore Runtime |
| <a name="output_user_pool_arn"></a> [user\_pool\_arn](#output\_user\_pool\_arn) | ARN of the Cognito User Pool created as JWT authentication fallback |
| <a name="output_user_pool_client_id"></a> [user\_pool\_client\_id](#output\_user\_pool\_client\_id) | ID of the Cognito User Pool Client |
| <a name="output_user_pool_endpoint"></a> [user\_pool\_endpoint](#output\_user\_pool\_endpoint) | Endpoint of the Cognito User Pool created as JWT authentication fallback |
| <a name="output_user_pool_id"></a> [user\_pool\_id](#output\_user\_pool\_id) | ID of the Cognito User Pool created as JWT authentication fallback |
| <a name="output_using_cognito_fallback"></a> [using\_cognito\_fallback](#output\_using\_cognito\_fallback) | Whether the module is using a Cognito User Pool as fallback for JWT authentication |
| <a name="output_workload_identity_arn"></a> [workload\_identity\_arn](#output\_workload\_identity\_arn) | ARN of the created Bedrock AgentCore Workload Identity |
| <a name="output_workload_identity_created_time"></a> [workload\_identity\_created\_time](#output\_workload\_identity\_created\_time) | Creation timestamp of the created Bedrock AgentCore Workload Identity |
| <a name="output_workload_identity_id"></a> [workload\_identity\_id](#output\_workload\_identity\_id) | ID of the created Bedrock AgentCore Workload Identity |
| <a name="output_workload_identity_last_updated_time"></a> [workload\_identity\_last\_updated\_time](#output\_workload\_identity\_last\_updated\_time) | Last update timestamp of the created Bedrock AgentCore Workload Identity |
<!-- END_TF_DOCS -->