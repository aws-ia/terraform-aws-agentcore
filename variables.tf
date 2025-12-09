# – Agent Core Runtime –

variable "create_runtime" {
  description = "Whether or not to create an agent core runtime."
  type        = bool
  default     = false
}

variable "runtime_name" {
  description = "The name of the agent core runtime."
  type        = string
  default     = "TerraformBedrockAgentCoreRuntime"
}

variable "runtime_description" {
  description = "Description of the agent runtime."
  type        = string
  default     = null
}

variable "runtime_role_arn" {
  description = "Optional external IAM role ARN for the Bedrock agent core runtime. If empty, the module will create one internally."
  type        = string
  default     = null
}

variable "runtime_artifact_type" {
  description = "The type of artifact to use for the agent core runtime. Valid values: container, code."
  type        = string
  default     = "container"

  validation {
    condition     = contains(["container", "code"], var.runtime_artifact_type)
    error_message = "The runtime_artifact_type must be either container or code."
  }
}

variable "runtime_container_uri" {
  description = "The ECR URI of the container for the agent core runtime. Required when runtime_artifact_type is set to 'container'."
  type        = string
  default     = null
}

variable "runtime_code_s3_bucket" {
  description = "S3 bucket containing the code package for the agent core runtime. Required when runtime_artifact_type is set to 'code'."
  type        = string
  default     = null
}

variable "runtime_code_s3_prefix" {
  description = "S3 prefix (key) for the code package. Required when runtime_artifact_type is set to 'code'."
  type        = string
  default     = null
}

variable "runtime_code_s3_version_id" {
  description = "S3 version ID of the code package. Optional when runtime_artifact_type is set to 'code'."
  type        = string
  default     = null
}

variable "runtime_code_entry_point" {
  description = "Entry point for the code runtime. Required when runtime_artifact_type is set to 'code'."
  type        = list(string)
  default     = null
}

variable "runtime_code_runtime_type" {
  description = "Runtime type for the code. Required when runtime_artifact_type is set to 'code'. Valid values: PYTHON_3_10, PYTHON_3_11, PYTHON_3_12, PYTHON_3_13"
  type        = string
  default     = null
  
  validation {
    condition     = var.runtime_code_runtime_type == null || contains(["PYTHON_3_10", "PYTHON_3_11", "PYTHON_3_12", "PYTHON_3_13"], var.runtime_code_runtime_type)
    error_message = "The runtime_code_runtime_type must be one of: PYTHON_3_10, PYTHON_3_11, PYTHON_3_12, PYTHON_3_13."
  }
}

variable "runtime_network_mode" {
  description = "Network mode configuration type for the agent core runtime. Valid values: PUBLIC, VPC."
  type        = string
  default     = "PUBLIC"

  validation {
    condition     = contains(["PUBLIC", "VPC"], var.runtime_network_mode)
    error_message = "The runtime_network_mode must be either PUBLIC or VPC."
  }
}

variable "runtime_network_configuration" {
  description = "VPC network configuration for the agent core runtime."
  type = object({
    security_groups = optional(list(string))
    subnets         = optional(list(string))
  })
  default = null
}

variable "runtime_environment_variables" {
  description = "Environment variables for the agent core runtime."
  type        = map(string)
  default     = null
}

variable "runtime_authorizer_configuration" {
  description = "Authorizer configuration for the agent core runtime."
  type = object({
    custom_jwt_authorizer = object({
      allowed_audience = optional(list(string))
      allowed_clients  = optional(list(string))
      discovery_url    = string
    })
  })
  default = null
}

variable "runtime_protocol_configuration" {
  description = "Protocol configuration for the agent core runtime."
  type        = string
  default     = null
}

variable "runtime_lifecycle_configuration" {
  description = "Lifecycle configuration for managing runtime sessions."
  type = object({
    idle_runtime_session_timeout = optional(number)
    max_lifetime                 = optional(number)
  })
  default = null
}

variable "runtime_request_header_configuration" {
  description = "Configuration for HTTP request headers."
  type = object({
    request_header_allowlist = optional(set(string))
  })
  default = null
}

variable "runtime_tags" {
  description = "A map of tag keys and values for the agent core runtime."
  type        = map(string)
  default     = null
}

# – Agent Core Runtime Endpoint –

variable "create_runtime_endpoint" {
  description = "Whether or not to create an agent core runtime endpoint."
  type        = bool
  default     = false
}

variable "runtime_endpoint_name" {
  description = "The name of the agent core runtime endpoint."
  type        = string
  default     = "TerraformBedrockAgentCoreRuntimeEndpoint"
}

variable "runtime_endpoint_description" {
  description = "Description of the agent core runtime endpoint."
  type        = string
  default     = null
}

variable "runtime_endpoint_agent_runtime_id" {
  description = "The ID of the agent core runtime associated with the endpoint. If not provided, it will use the ID of the agent runtime created by this module."
  type        = string
  default     = null
}

variable "runtime_endpoint_tags" {
  description = "A map of tag keys and values for the agent core runtime endpoint."
  type        = map(string)
  default     = null
}

# – Agent Core Memory –

variable "create_memory" {
  description = "Whether or not to create an agent core memory."
  type        = bool
  default     = false
}

variable "memory_name" {
  description = "The name of the agent core memory."
  type        = string
  default     = "TerraformBedrockAgentCoreMemory"
}

variable "memory_description" {
  description = "Description of the agent core memory."
  type        = string
  default     = null
}

variable "memory_event_expiry_duration" {
  description = "Duration in days until memory events expire."
  type        = number
  default     = 90
}

variable "memory_execution_role_arn" {
  description = "Optional IAM role ARN for the Bedrock agent core memory."
  type        = string
  default     = null
}

variable "memory_encryption_key_arn" {
  description = "The ARN of the KMS key used to encrypt the memory."
  type        = string
  default     = null
}

variable "memory_strategies" {
  description = "List of memory strategies attached to this memory."
  type = list(object({
    semantic_memory_strategy = optional(object({
      name = optional(string)
      description = optional(string)
      namespaces = optional(list(string))
    }))
    summary_memory_strategy = optional(object({
      name = optional(string)
      description = optional(string)
      namespaces = optional(list(string))
    }))
    user_preference_memory_strategy = optional(object({
      name = optional(string)
      description = optional(string)
      namespaces = optional(list(string))
    }))
    custom_memory_strategy = optional(object({
      name = optional(string)
      description = optional(string)
      namespaces = optional(list(string))
      configuration = optional(object({
        self_managed_configuration = optional(object({
          historical_context_window_size = optional(number, 4) # Default to 4 messages
          invocation_configuration = object({
            # Both fields are required when a self-managed configuration is used
            payload_delivery_bucket_name = string
            topic_arn = string
          })
          trigger_conditions = optional(list(object({
            message_based_trigger = optional(object({
              message_count = optional(number, 1) # Default to 1 message
            }))
            time_based_trigger = optional(object({
              idle_session_timeout = optional(number, 10) # Default to 10 seconds
            }))
            token_based_trigger = optional(object({
              token_count = optional(number, 100) # Default to 100 tokens
            }))
          })))
        }))
        semantic_override = optional(object({
          consolidation = optional(object({
            append_to_prompt = optional(string)
            model_id = optional(string)
          }))
          extraction = optional(object({
            append_to_prompt = optional(string)
            model_id = optional(string)
          }))
        }))
        summary_override = optional(object({
          consolidation = optional(object({
            append_to_prompt = optional(string)
            model_id = optional(string)
          }))
        }))
        user_preference_override = optional(object({
          consolidation = optional(object({
            append_to_prompt = optional(string)
            model_id = optional(string)
          }))
          extraction = optional(object({
            append_to_prompt = optional(string)
            model_id = optional(string)
          }))
        }))
      }))
    }))
  }))
  default = []
}

variable "memory_tags" {
  description = "A map of tag keys and values for the agent core memory."
  type        = map(string)
  default     = null
}

# – Agent Core Gateway –

variable "create_gateway" {
  description = "Whether or not to create an agent core gateway."
  type        = bool
  default     = false
}

variable "gateway_name" {
  description = "The name of the agent core gateway."
  type        = string
  default     = "TerraformBedrockAgentCoreGateway"
}

variable "gateway_description" {
  description = "Description of the agent core gateway."
  type        = string
  default     = null
}

variable "gateway_role_arn" {
  description = "Optional external IAM role ARN for the Bedrock agent core gateway. If empty, the module will create one internally."
  type        = string
  default     = null
}

variable "gateway_authorizer_type" {
  description = "The authorizer type for the gateway. Valid values: AWS_IAM, CUSTOM_JWT."
  type        = string
  default     = "CUSTOM_JWT"

  validation {
    condition     = contains(["AWS_IAM", "CUSTOM_JWT"], var.gateway_authorizer_type)
    error_message = "The gateway_authorizer_type must be either AWS_IAM or CUSTOM_JWT."
  }
}

variable "gateway_protocol_type" {
  description = "The protocol type for the gateway. Valid value: MCP."
  type        = string
  default     = "MCP"

  validation {
    condition     = var.gateway_protocol_type == "MCP"
    error_message = "The gateway_protocol_type must be MCP."
  }
}

variable "gateway_exception_level" {
  description = "Exception level for the gateway. Valid values: PARTIAL, FULL."
  type        = string
  default     = null

  validation {
    condition     = var.gateway_exception_level == null || try(contains(["PARTIAL", "FULL"], var.gateway_exception_level), true)
    error_message = "The gateway_exception_level must be either PARTIAL or FULL."
  }
}

variable "gateway_kms_key_arn" {
  description = "The ARN of the KMS key used to encrypt the gateway."
  type        = string
  default     = null
}

variable "gateway_authorizer_configuration" {
  description = "Authorizer configuration for the agent core gateway."
  type = object({
    custom_jwt_authorizer = object({
      allowed_audience = optional(list(string))
      allowed_clients  = optional(list(string))
      discovery_url    = string
    })
  })
  default = null
}

variable "gateway_protocol_configuration" {
  description = "Protocol configuration for the agent core gateway."
  type = object({
    mcp = object({
      instructions       = optional(string)
      search_type        = optional(string)
      supported_versions = optional(list(string))
    })
  })
  default = null
}

variable "gateway_tags" {
  description = "A map of tag keys and values for the agent core gateway."
  type        = map(string)
  default     = null
}

variable "gateway_allow_create_permissions" {
  description = "Whether to allow create permissions for the gateway."
  type        = bool
  default     = true
}

variable "gateway_allow_update_delete_permissions" {
  description = "Whether to allow update and delete permissions for the gateway."
  type        = bool
  default     = false
}

# - IAM -
variable "permissions_boundary_arn" {
  description = "The ARN of the IAM permission boundary for the role."
  type        = string
  default     = null
}

# - Lambda Function Access -
variable "gateway_lambda_function_arns" {
  description = "List of Lambda function ARNs that the gateway service role should be able to invoke. Required when using Lambda targets."
  type        = list(string)
  default     = []
}

variable "gateway_cross_account_lambda_permissions" {
  description = "Configuration for cross-account Lambda function access. Required only if Lambda functions are in different AWS accounts."
  type = list(object({
    lambda_function_arn      = string
    gateway_service_role_arn = string
  }))
  default = []
}

# - OAuth Outbound Authorization -
variable "enable_oauth_outbound_auth" {
  description = "Whether to enable outbound authorization with an OAuth client for the gateway."
  type        = bool
  default     = false
}

variable "oauth_credential_provider_arn" {
  description = "ARN of the OAuth credential provider created with CreateOauth2CredentialProvider. Required when enable_oauth_outbound_auth is true."
  type        = string
  default     = null
}

variable "oauth_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret containing the OAuth client credentials. Required when enable_oauth_outbound_auth is true."
  type        = string
  default     = null
}

# - API Key Outbound Authorization -
variable "enable_apikey_outbound_auth" {
  description = "Whether to enable outbound authorization with an API key for the gateway."
  type        = bool
  default     = false
}

variable "apikey_credential_provider_arn" {
  description = "ARN of the API key credential provider created with CreateApiKeyCredentialProvider. Required when enable_apikey_outbound_auth is true."
  type        = string
  default     = null
}

variable "apikey_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret containing the API key. Required when enable_apikey_outbound_auth is true."
  type        = string
  default     = null
}

# – Agent Core Browser Custom –

variable "create_browser" {
  description = "Whether or not to create an agent core browser custom."
  type        = bool
  default     = false
}

variable "browser_name" {
  description = "The name of the agent core browser. Valid characters are a-z, A-Z, 0-9, _ (underscore). The name must start with a letter and can be up to 48 characters long."
  type        = string
  default     = "TerraformBedrockAgentCoreBrowser"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,47}$", var.browser_name))
    error_message = "The browser_name must start with a letter and can only include letters, numbers, and underscores, with a maximum length of 48 characters."
  }
}

variable "browser_description" {
  description = "Description of the agent core browser."
  type        = string
  default     = null
}

variable "browser_role_arn" {
  description = "Optional external IAM role ARN for the Bedrock agent core browser. If empty, the module will create one internally."
  type        = string
  default     = null
}

variable "browser_network_mode" {
  description = "Network mode configuration type for the agent core browser. Valid values: PUBLIC, VPC."
  type        = string
  default     = "PUBLIC"

  validation {
    condition     = contains(["PUBLIC", "VPC"], var.browser_network_mode)
    error_message = "The browser_network_mode must be either PUBLIC or VPC."
  }
}

variable "browser_network_configuration" {
  description = "VPC network configuration for the agent core browser. Required when browser_network_mode is set to 'VPC'."
  type = object({
    security_groups = optional(list(string))
    subnets         = optional(list(string))
  })
  default = null
  
  validation {
    condition     = var.browser_network_configuration == null || (try(length(coalesce(var.browser_network_configuration.security_groups, [])), 0) > 0 && try(length(coalesce(var.browser_network_configuration.subnets, [])), 0) > 0)
    error_message = "When providing browser_network_configuration, you must include at least one security group and one subnet."
  }
}

variable "browser_recording_enabled" {
  description = "Whether to enable browser session recording to S3."
  type        = bool
  default     = false
}

variable "browser_recording_config" {
  description = "Configuration for browser session recording when enabled. Bucket name must follow S3 naming conventions (lowercase alphanumeric characters, dots, and hyphens), between 3 and 63 characters, starting and ending with alphanumeric character."
  type = object({
    bucket = string
    prefix = string
  })
  default = null
  
  validation {
    condition = var.browser_recording_config == null || try(can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.browser_recording_config.bucket)), false)
    error_message = "S3 bucket name must follow naming conventions: lowercase alphanumeric characters, dots and hyphens, 3-63 characters long, starting and ending with alphanumeric character."
  }
  
  validation {
    condition = var.browser_recording_config == null || try(var.browser_recording_config.prefix != null, true)
    error_message = "When providing a recording configuration, the S3 prefix cannot be null."
  }
}

variable "browser_tags" {
  description = "A map of tag keys and values for the agent core browser. Each tag key and value must be between 1 and 256 characters and can only include alphanumeric characters, spaces, and the following special characters: _ . : / = + @ -"
  type        = map(string)
  default     = null
  
  validation {
    condition = var.browser_tags == null || alltrue(try([
      for k, v in var.browser_tags : 
        length(k) >= 1 && length(k) <= 256 && 
        length(v) >= 1 && length(v) <= 256
    ], [true]))
    error_message = "Each tag key and value must be between 1 and 256 characters in length."
  }
  
  validation {
    condition = var.browser_tags == null || alltrue(try([
      for k, v in var.browser_tags : 
        can(regex("^[a-zA-Z0-9\\s._:/=+@-]*$", k)) && 
        can(regex("^[a-zA-Z0-9\\s._:/=+@-]*$", v))
    ], [true]))
    error_message = "Tag keys and values can only include alphanumeric characters, spaces, and the following special characters: _ . : / = + @ -"
  }
}

# – Agent Core Code Interpreter Custom –

variable "create_code_interpreter" {
  description = "Whether or not to create an agent core code interpreter custom."
  type        = bool
  default     = false
}

variable "code_interpreter_name" {
  description = "The name of the agent core code interpreter. Valid characters are a-z, A-Z, 0-9, _ (underscore). The name must start with a letter and can be up to 48 characters long."
  type        = string
  default     = "TerraformBedrockAgentCoreCodeInterpreter"
  
  validation {
    condition     = length(var.code_interpreter_name) >= 1 && length(var.code_interpreter_name) <= 48
    error_message = "The code_interpreter_name must be between 1 and 48 characters in length."
  }
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,47}$", var.code_interpreter_name))
    error_message = "The code_interpreter_name must start with a letter and can only include letters, numbers, and underscores."
  }
}

variable "code_interpreter_description" {
  description = "Description of the agent core code interpreter. Valid characters are a-z, A-Z, 0-9, _ (underscore), - (hyphen) and spaces. The description can have up to 200 characters."
  type        = string
  default     = null
  
  validation {
    condition     = var.code_interpreter_description == null || try(length(var.code_interpreter_description) <= 200, true)
    error_message = "The code_interpreter_description must be 200 characters or less."
  }
  
  validation {
    condition     = var.code_interpreter_description == null || try(can(regex("^[a-zA-Z0-9_\\- ]*$", var.code_interpreter_description)), true)
    error_message = "The code_interpreter_description can only include letters, numbers, underscores, hyphens, and spaces."
  }
}

variable "code_interpreter_role_arn" {
  description = "Optional external IAM role ARN for the Bedrock agent core code interpreter. If empty, the module will create one internally."
  type        = string
  default     = null
}

variable "code_interpreter_network_mode" {
  description = "Network mode configuration type for the agent core code interpreter. Valid values: SANDBOX, VPC."
  type        = string
  default     = "SANDBOX"

  validation {
    condition     = contains(["SANDBOX", "VPC"], var.code_interpreter_network_mode)
    error_message = "The code_interpreter_network_mode must be either SANDBOX or VPC."
  }
}

variable "code_interpreter_network_configuration" {
  description = "VPC network configuration for the agent core code interpreter."
  type = object({
    security_groups = optional(list(string))
    subnets         = optional(list(string))
  })
  default = null
}

variable "code_interpreter_tags" {
  description = "A map of tag keys and values for the agent core code interpreter. Each tag key and value must be between 1 and 256 characters and can only include alphanumeric characters, spaces, and the following special characters: _ . : / = + @ -"
  type        = map(string)
  default     = null
  
  validation {
    condition = var.code_interpreter_tags == null || alltrue(try([
      for k, v in var.code_interpreter_tags : 
        length(k) >= 1 && length(k) <= 256 && 
        length(v) >= 1 && length(v) <= 256
    ], [true]))
    error_message = "Each tag key and value must be between 1 and 256 characters in length."
  }
  
  validation {
    condition = var.code_interpreter_tags == null || alltrue(try([
      for k, v in var.code_interpreter_tags : 
        can(regex("^[a-zA-Z0-9\\s._:/=+@-]*$", k)) && 
        can(regex("^[a-zA-Z0-9\\s._:/=+@-]*$", v))
    ], [true]))
    error_message = "Tag keys and values can only include alphanumeric characters, spaces, and the following special characters: _ . : / = + @ -"
  }
}

# – Agent Core Gateway Target –

variable "create_gateway_target" {
  description = "Whether or not to create a Bedrock agent core gateway target."
  type        = bool
  default     = false
}

variable "gateway_target_name" {
  description = "The name of the gateway target."
  type        = string
  default     = "TerraformBedrockAgentCoreGatewayTarget"
}

variable "gateway_target_gateway_id" {
  description = "Identifier of the gateway that this target belongs to. If not provided, it will use the ID of the gateway created by this module."
  type        = string
  default     = null
}

variable "gateway_target_description" {
  description = "Description of the gateway target."
  type        = string
  default     = null
}

variable "gateway_target_credential_provider_type" {
  description = "Type of credential provider to use for the gateway target. Valid values: GATEWAY_IAM_ROLE, API_KEY, OAUTH."
  type        = string
  default     = "GATEWAY_IAM_ROLE"
  
  validation {
    condition     = var.gateway_target_credential_provider_type == null || contains(["GATEWAY_IAM_ROLE", "API_KEY", "OAUTH"], var.gateway_target_credential_provider_type)
    error_message = "The gateway_target_credential_provider_type must be one of GATEWAY_IAM_ROLE, API_KEY, OAUTH, or null."
  }
}

variable "gateway_target_api_key_config" {
  description = "Configuration for API key authentication for the gateway target."
  type = object({
    provider_arn              = string
    credential_location       = optional(string)
    credential_parameter_name = optional(string)
    credential_prefix         = optional(string)
  })
  default = null
}

variable "gateway_target_oauth_config" {
  description = "Configuration for OAuth authentication for the gateway target."
  type = object({
    provider_arn      = string
    scopes            = optional(list(string))
    custom_parameters = optional(map(string))
  })
  default = null
}

variable "gateway_target_type" {
  description = "Type of target to create. Valid values: LAMBDA, MCP_SERVER."
  type        = string
  default     = "LAMBDA"
  
  validation {
    condition     = var.gateway_target_type == null || contains(["LAMBDA", "MCP_SERVER"], var.gateway_target_type)
    error_message = "The gateway_target_type must be one of LAMBDA, MCP_SERVER, or null."
  }
}

variable "gateway_target_lambda_config" {
  description = "Configuration for Lambda function target."
  type = object({
    lambda_arn       = string
    tool_schema_type = string # INLINE or S3
    inline_schema    = optional(object({
      name        = string
      description = string
      input_schema = object({
        type        = string
        description = optional(string)
        properties  = optional(list(object({
          name             = string
          type             = string
          description      = optional(string)
          required         = optional(bool, false)
          nested_properties = optional(list(object({
            name        = string
            type        = string
            description = optional(string)
            required    = optional(bool)
          })))
          items = optional(object({
            type        = string
            description = optional(string)
          }))
        })))
        items = optional(object({
          type        = string
          description = optional(string)
        }))
      })
      output_schema = optional(object({
        type        = string
        description = optional(string)
        properties  = optional(list(object({
          name        = string
          type        = string
          description = optional(string)
          required    = optional(bool)
        })))
        items = optional(object({
          type        = string
          description = optional(string)
        }))
      }))
    }))
    s3_schema = optional(object({
      uri                     = string
      bucket_owner_account_id = optional(string)
    }))
  })
  default = null
}

variable "gateway_target_mcp_server_config" {
  description = "Configuration for MCP server target."
  type = object({
    endpoint = string
  })
  default = null
}

# – Agent Core Workload Identity –

variable "create_workload_identity" {
  description = "Whether or not to create a Bedrock agent core workload identity."
  type        = bool
  default     = false
}

variable "workload_identity_name" {
  description = "The name of the workload identity."
  type        = string
  default     = "TerraformBedrockAgentCoreWorkloadIdentity"
}

variable "workload_identity_allowed_resource_oauth_2_return_urls" {
  description = "The list of allowed OAuth2 return URLs for resources associated with this workload identity."
  type        = list(string)
  default     = null
}

variable "workload_identity_tags" {
  description = "A map of tag keys and values for the workload identity."
  type        = map(string)
  default     = null
}

# – Cognito User Pool (for JWT Authentication Fallback) –

variable "user_pool_name" {
  description = "The name of the Cognito User Pool to create when JWT auth info is not provided."
  type        = string
  default     = "AgentCoreUserPool"
}

variable "user_pool_password_policy" {
  description = "Password policy for the Cognito User Pool."
  type = object({
    minimum_length    = optional(number, 8)
    require_lowercase = optional(bool, true)
    require_numbers   = optional(bool, true)
    require_symbols   = optional(bool, true)
    require_uppercase = optional(bool, true)
  })
  default = {}
}

variable "user_pool_mfa_configuration" {
  description = "MFA configuration for the Cognito User Pool. Valid values: OFF, OPTIONAL, REQUIRED."
  type        = string
  default     = "OFF"

  validation {
    condition     = contains(["OFF", "OPTIONAL", "REQUIRED"], var.user_pool_mfa_configuration)
    error_message = "The user_pool_mfa_configuration must be one of OFF, OPTIONAL, or REQUIRED."
  }
}

variable "user_pool_allowed_clients" {
  description = "List of allowed clients for the Cognito User Pool JWT authorizer."
  type        = list(string)
  default     = []
}

variable "user_pool_callback_urls" {
  description = "List of allowed callback URLs for the Cognito User Pool client."
  type        = list(string)
  default     = ["http://localhost:3000"]
}

variable "user_pool_logout_urls" {
  description = "List of allowed logout URLs for the Cognito User Pool client."
  type        = list(string)
  default     = ["http://localhost:3000"]
}

variable "user_pool_token_validity_hours" {
  description = "Number of hours that ID and access tokens are valid for."
  type        = number
  default     = 24
}

variable "user_pool_refresh_token_validity_days" {
  description = "Number of days that refresh tokens are valid for."
  type        = number
  default     = 30
}

variable "user_pool_create_admin" {
  description = "Whether to create an admin user in the Cognito User Pool."
  type        = bool
  default     = false
}

variable "user_pool_admin_email" {
  description = "Email address for the admin user."
  type        = string
  default     = "admin@example.com"
}

variable "user_pool_tags" {
  description = "A map of tag keys and values for the Cognito User Pool."
  type        = map(string)
  default     = null
}
