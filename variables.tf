# – Agent Core Runtimes –
variable "project_prefix" {
  description = "Prefix for all AWS resource names created by this module. Helps identify and organize resources."
  type        = string
  default     = "agentcore"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,20}$", var.project_prefix))
    error_message = "project_prefix must be lowercase alphanumeric with hyphens, max 20 characters."
  }
}

variable "tags" {
  description = "Tags to apply to all resources created by this module."
  type        = map(string)
  default = {
    IaC           = "Terraform"
    ModuleName    = "terraform-aws-agentcore"
    ModuleSource  = "https://github.com/aws-ia/terraform-aws-agentcore"
    ModuleVersion = "" # Set dynamically from VERSION file in locals
  }
}

variable "debug" {
  description = "Enable debug mode: generates .env files with actual resource IDs in code_source_path directories for local testing."
  type        = bool
  default     = false
}

variable "runtimes" {
  description = "Map of AgentCore runtimes to create. Each key is the runtime name."
  type = map(object({
    source_type = string # "CODE" or "CONTAINER"

    # CODE: Module-managed (provide source_path)
    code_source_path = optional(string)

    # CODE: User-managed (provide s3_bucket)
    code_s3_bucket     = optional(string)
    code_s3_key        = optional(string)
    code_s3_version_id = optional(string)

    # CODE: Required for both
    code_entry_point = optional(list(string))
    code_runtime     = optional(string, "PYTHON_3_11") # Default to PYTHON_3_11

    # CONTAINER: Module-managed (provide source_path)
    container_source_path     = optional(string)
    container_dockerfile_name = optional(string, "Dockerfile")
    container_image_tag       = optional(string, "latest")

    # CONTAINER: User-managed (provide image_uri)
    container_image_uri = optional(string)

    # Shared configuration
    execution_role_arn       = optional(string) # Required for user-managed
    description              = optional(string)
    execution_network_mode   = optional(string, "PUBLIC")
    execution_network_config = optional(object({
      security_groups = list(string)
      subnets         = list(string)
    }))
    environment_variables = optional(map(string), {})

    create_endpoint      = optional(bool, true)
    endpoint_description = optional(string)
    tags                 = optional(map(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, config in var.runtimes :
      can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,47}$", name))
    ])
    error_message = "Runtime names must start with a letter and contain only letters, numbers, and underscores (max 48 characters)."
  }

  validation {
    condition = alltrue([
      for name, config in var.runtimes :
      contains(["CODE", "CONTAINER"], config.source_type)
    ])
    error_message = "source_type must be either 'CODE' or 'CONTAINER'."
  }

  validation {
    condition = alltrue([
      for name, config in var.runtimes :
      config.source_type != "CODE" || (
        (config.code_source_path != null && config.code_s3_bucket == null) ||
        (config.code_source_path == null && config.code_s3_bucket != null)
      )
    ])
    error_message = "For CODE source_type: provide either code_source_path (module-managed) OR code_s3_bucket (user-managed), not both."
  }

  validation {
    condition = alltrue([
      for name, config in var.runtimes :
      config.source_type != "CODE" || config.code_runtime == null || contains(["PYTHON_3_10", "PYTHON_3_11", "PYTHON_3_12", "PYTHON_3_13"], config.code_runtime)
    ])
    error_message = "code_runtime must be one of: PYTHON_3_10, PYTHON_3_11, PYTHON_3_12, PYTHON_3_13."
  }

  validation {
    condition = alltrue([
      for name, config in var.runtimes :
      config.source_type != "CODE" || config.code_entry_point != null
    ])
    error_message = "code_entry_point is required when source_type is CODE."
  }

  validation {
    condition = alltrue([
      for name, config in var.runtimes :
      config.source_type != "CONTAINER" || (
        (config.container_source_path != null && config.container_image_uri == null) ||
        (config.container_source_path == null && config.container_image_uri != null)
      )
    ])
    error_message = "For CONTAINER source_type: provide either container_source_path (module-managed) OR container_image_uri (user-managed), not both."
  }

  validation {
    condition = alltrue([
      for name, config in var.runtimes :
      !(config.source_type == "CODE" && config.code_s3_bucket != null && config.execution_role_arn == null)
    ])
    error_message = "execution_role_arn is required when using user-managed CODE (code_s3_bucket provided)."
  }

  validation {
    condition = alltrue([
      for name, config in var.runtimes :
      !(config.source_type == "CONTAINER" && config.container_image_uri != null && config.execution_role_arn == null)
    ])
    error_message = "execution_role_arn is required when using user-managed CONTAINER (container_image_uri provided)."
  }

  validation {
    condition = alltrue([
      for name, config in var.runtimes :
      config.execution_network_mode != "VPC" || config.execution_network_config != null
    ])
    error_message = "execution_network_config is required when execution_network_mode is VPC."
  }
}

# – Agent Core Memories –

variable "memories" {
  description = "Map of AgentCore memories to create. Each key is the memory name. NOTE: Each memory can only have ONE strategy."
  type = map(object({
    description           = optional(string)
    event_expiry_duration = optional(number, 90)
    execution_role_arn    = optional(string)
    encryption_key_arn    = optional(string)
    
    strategies = optional(list(object({
      semantic_memory_strategy = optional(object({
        name        = optional(string)
        description = optional(string)
        namespaces  = optional(list(string))
      }))
      summary_memory_strategy = optional(object({
        name        = optional(string)
        description = optional(string)
        namespaces  = optional(list(string))
      }))
      user_preference_memory_strategy = optional(object({
        name        = optional(string)
        description = optional(string)
        namespaces  = optional(list(string))
      }))
      custom_memory_strategy = optional(object({
        name        = optional(string)
        description = optional(string)
        namespaces  = optional(list(string))
        configuration = optional(object({
          self_managed_configuration = optional(object({
            historical_context_window_size = optional(number, 4)
            invocation_configuration = object({
              payload_delivery_bucket_name = string
              topic_arn                    = string
            })
            trigger_conditions = optional(list(object({
              message_based_trigger = optional(object({
                message_count = optional(number, 1)
              }))
              time_based_trigger = optional(object({
                idle_session_timeout = optional(number, 10)
              }))
              token_based_trigger = optional(object({
                token_count = optional(number, 100)
              }))
            })))
          }))
          semantic_override = optional(object({
            consolidation = optional(object({
              append_to_prompt = optional(string)
              model_id         = optional(string)
            }))
            extraction = optional(object({
              append_to_prompt = optional(string)
              model_id         = optional(string)
            }))
          }))
          summary_override = optional(object({
            consolidation = optional(object({
              append_to_prompt = optional(string)
              model_id         = optional(string)
            }))
          }))
          user_preference_override = optional(object({
            consolidation = optional(object({
              append_to_prompt = optional(string)
              model_id         = optional(string)
            }))
            extraction = optional(object({
              append_to_prompt = optional(string)
              model_id         = optional(string)
            }))
          }))
        }))
      }))
    })), [])
    
    tags = optional(map(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, config in var.memories :
      length(config.strategies) <= 1
    ])
    error_message = "Each memory can only have ONE strategy. To use multiple strategies, create separate memory resources."
  }
}

# – Agent Core Gateways –

variable "gateways" {
  description = "Map of AgentCore gateways to create. Each key is the gateway name."
  type = map(object({
    description      = optional(string)
    role_arn         = optional(string)
    authorizer_type  = optional(string, "AWS_IAM")
    protocol_type    = optional(string, "MCP")
    exception_level  = optional(string, "DEBUG")
    kms_key_arn      = optional(string)
    
    authorizer_configuration = optional(object({
      custom_jwt_authorizer = object({
        allowed_audience = list(string)
        allowed_clients  = optional(list(string))
        discovery_url    = string
      })
    }))
    
    protocol_configuration = optional(object({
      mcp = object({
        instructions       = optional(string)
        search_type        = optional(string, "SEMANTIC")
        supported_versions = optional(list(string), ["1.0.0"])
      })
    }))
    
    interceptor_configurations = optional(list(object({
      interception_points = list(string)
      interceptor = object({
        lambda = object({
          arn = string
        })
      })
      input_configuration = optional(object({
        pass_request_headers = optional(bool, false)
      }))
    })), [])
    
    tags = optional(map(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, config in var.gateways :
      can(regex("^([0-9a-zA-Z][-]?){1,100}$", name))
    ])
    error_message = "Gateway names must match pattern ^([0-9a-zA-Z][-]?){1,100}$ (alphanumeric with optional hyphens, no underscores)."
  }
}

variable "gateway_targets" {
  description = "Map of AgentCore gateway targets to create. Each key is the target name."
  type = map(object({
    gateway_name                = string
    description                 = optional(string)
    credential_provider_type    = optional(string)
    
    api_key_config = optional(object({
      provider_arn              = string
      credential_location       = string
      credential_parameter_name = string
      credential_prefix         = optional(string)
    }))
    
    oauth_config = optional(object({
      provider_arn      = string
      scopes            = optional(list(string))
      custom_parameters = optional(map(string))
    }))
    
    type = string # "LAMBDA" or "MCP_SERVER"
    
    lambda_config = optional(object({
      lambda_arn       = string
      tool_schema_type = string # "INLINE" or "S3"
      
      inline_schema = optional(object({
        name        = string
        description = optional(string)
        
        input_schema = object({
          type        = string
          description = optional(string)
          properties  = optional(list(any))
          items       = optional(any)
        })
        
        output_schema = optional(object({
          type        = string
          description = optional(string)
          properties  = optional(list(any))
          items       = optional(any)
        }))
      }))
      
      s3_schema = optional(object({
        uri                     = string
        bucket_owner_account_id = optional(string)
      }))
    }))
    
    mcp_server_config = optional(object({
      endpoint = string
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, config in var.gateway_targets :
      can(regex("^([0-9a-zA-Z][-]?){1,100}$", name))
    ])
    error_message = "Gateway target names must match pattern ^([0-9a-zA-Z][-]?){1,100}$ (alphanumeric with optional hyphens, no underscores)."
  }
}

# – Agent Core Browsers –

variable "browsers" {
  description = "Map of AgentCore custom browsers to create. Each key is the browser name."
  type = map(object({
    description          = optional(string)
    execution_role_arn   = optional(string)
    network_mode         = optional(string, "PUBLIC")
    
    network_configuration = optional(object({
      security_groups = list(string)
      subnets         = list(string)
    }))
    
    recording_enabled = optional(bool, false)
    
    recording_config = optional(object({
      bucket = string
      prefix = string
    }))
    
    tags = optional(map(string))
  }))
  default = {}
}

# – Agent Core Code Interpreters –

variable "code_interpreters" {
  description = "Map of AgentCore custom code interpreters to create. Each key is the interpreter name."
  type = map(object({
    description          = optional(string)
    execution_role_arn   = optional(string)
    network_mode         = optional(string, "SANDBOX")
    
    network_configuration = optional(object({
      security_groups = list(string)
      subnets         = list(string)
    }))
    
    tags = optional(map(string))
  }))
  default = {}
}

