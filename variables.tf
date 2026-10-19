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
    execution_role_arn     = optional(string) # Required for user-managed
    description            = optional(string)
    execution_network_mode = optional(string, "PUBLIC")
    execution_network_config = optional(object({
      security_groups = list(string)
      subnets         = list(string)
    }))
    environment_variables = optional(map(string), {})

    # Protocol the agent serves ("HTTP", "MCP", "A2A" or "AGUI"; service default HTTP)
    protocol_configuration = optional(string)
    platform_version       = optional(string)

    # Session lifecycle (seconds). Service defaults: 900 idle, 28800 max lifetime
    lifecycle_configuration = optional(object({
      idle_runtime_session_timeout = optional(number)
      max_lifetime                 = optional(number)
    }))

    # HTTP headers forwarded to the agent (max 20; x-amzn-* only with the X-Amzn-Bedrock-AgentCore-Runtime-Custom- prefix)
    request_header_allowlist = optional(list(string))

    # Inbound JWT authorization (default: AWS IAM / SigV4)
    authorizer_configuration = optional(object({
      custom_jwt_authorizer = object({
        discovery_url    = string
        allowed_audience = optional(list(string))
        allowed_clients  = optional(list(string))
        allowed_scopes   = optional(list(string))
        custom_claims = optional(list(object({
          inbound_token_claim_name       = string
          inbound_token_claim_value_type = optional(string, "STRING") # "STRING" or "STRING_ARRAY"
          claim_match_operator           = optional(string, "EQUALS") # "EQUALS" (STRING), "CONTAINS" or "CONTAINS_ANY" (STRING_ARRAY)
          match_value_string             = optional(string)
          match_value_string_list        = optional(list(string))
        })), [])
        # Only accept requests whose identity chain includes these workloads (e.g. a gateway)
        allowed_workload_configuration = optional(object({
          workload_identities      = optional(list(string), [])
          hosting_environment_arns = optional(list(string), [])
        }))
      })
    }))

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

  validation {
    condition = alltrue([
      for name, config in var.runtimes :
      config.protocol_configuration == null || contains(["HTTP", "MCP", "A2A", "AGUI"], config.protocol_configuration)
    ])
    error_message = "protocol_configuration must be one of: HTTP, MCP, A2A, AGUI."
  }

  validation {
    condition = alltrue([
      for name, config in var.runtimes :
      config.lifecycle_configuration == null || alltrue([
        for seconds in [config.lifecycle_configuration.idle_runtime_session_timeout, config.lifecycle_configuration.max_lifetime] :
        seconds == null || (seconds >= 60 && seconds <= 1209600)
      ])
    ])
    error_message = "lifecycle_configuration values are in seconds and must be between 60 and 1209600 (microVM runtimes accept up to 28800)."
  }

  validation {
    condition = alltrue([
      for name, config in var.runtimes :
      config.lifecycle_configuration == null || config.lifecycle_configuration.idle_runtime_session_timeout == null || config.lifecycle_configuration.max_lifetime == null || config.lifecycle_configuration.idle_runtime_session_timeout <= config.lifecycle_configuration.max_lifetime
    ])
    error_message = "lifecycle_configuration.idle_runtime_session_timeout must be less than or equal to max_lifetime."
  }

  validation {
    condition = alltrue([
      for name, config in var.runtimes :
      config.request_header_allowlist == null || (
        length(config.request_header_allowlist) <= 20 && alltrue([
          for header in config.request_header_allowlist :
          !startswith(lower(header), "x-amzn-") || startswith(lower(header), "x-amzn-bedrock-agentcore-runtime-custom-")
        ])
      )
    ])
    error_message = "request_header_allowlist accepts up to 20 headers; x-amzn-* headers are only allowed with the X-Amzn-Bedrock-AgentCore-Runtime-Custom- prefix."
  }

  validation {
    condition = alltrue([
      for name, config in var.runtimes :
      config.authorizer_configuration == null || (
        try(length(config.authorizer_configuration.custom_jwt_authorizer.allowed_audience), 0) +
        try(length(config.authorizer_configuration.custom_jwt_authorizer.allowed_clients), 0) +
        try(length(config.authorizer_configuration.custom_jwt_authorizer.allowed_scopes), 0) +
        length(config.authorizer_configuration.custom_jwt_authorizer.custom_claims)
      ) > 0
    ])
    error_message = "custom_jwt_authorizer needs at least one of allowed_audience, allowed_clients, allowed_scopes or custom_claims."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.runtimes : [
        for claim in(config.authorizer_configuration == null ? [] : config.authorizer_configuration.custom_jwt_authorizer.custom_claims) :
        (claim.inbound_token_claim_value_type == "STRING" && claim.claim_match_operator == "EQUALS" && claim.match_value_string != null) ||
        (claim.inbound_token_claim_value_type == "STRING_ARRAY" && contains(["CONTAINS", "CONTAINS_ANY"], claim.claim_match_operator) && claim.match_value_string_list != null)
      ]
    ]))
    error_message = "custom_claims: STRING claims use claim_match_operator EQUALS with match_value_string; STRING_ARRAY claims use CONTAINS or CONTAINS_ANY with match_value_string_list."
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
    description     = optional(string)
    role_arn        = optional(string)
    authorizer_type = optional(string, "AWS_IAM")
    protocol_type   = optional(string, "MCP") # "MCP", or "NONE" for a gateway with HTTP targets (runtime, passthrough)
    exception_level = optional(string, "DEBUG")
    kms_key_arn     = optional(string)

    authorizer_configuration = optional(object({
      custom_jwt_authorizer = object({
        discovery_url    = string
        allowed_audience = optional(list(string))
        allowed_clients  = optional(list(string))
        allowed_scopes   = optional(list(string))
        custom_claims = optional(list(object({
          inbound_token_claim_name       = string
          inbound_token_claim_value_type = optional(string, "STRING") # "STRING" or "STRING_ARRAY"
          claim_match_operator           = optional(string, "EQUALS") # "EQUALS" (STRING), "CONTAINS" or "CONTAINS_ANY" (STRING_ARRAY)
          match_value_string             = optional(string)
          match_value_string_list        = optional(list(string))
        })), [])
        # Scope advertised to clients (OAuth protected resource metadata) for each allowed scope
        advertised_scope_mapping = optional(map(string))
      })
    }))

    protocol_configuration = optional(object({
      mcp = object({
        instructions               = optional(string)
        search_type                = optional(string, "SEMANTIC")
        supported_versions         = optional(list(string), ["1.0.0"])
        session_timeout_in_seconds = optional(number) # 900-28800 (service default 3600)
        enable_response_streaming  = optional(bool)
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
        exclude_fields       = optional(list(string), []) # e.g. ["RESPONSE_BODY"] for HTTP and inference targets
      }))
    })), [])

    # AWS WAF: behaviour when WAF cannot be evaluated, and an optional regional web ACL to associate
    waf_configuration = optional(object({
      failure_mode = optional(string, "FAIL_CLOSE") # "FAIL_CLOSE" or "FAIL_OPEN"
      web_acl_arn  = optional(string)
    }))

    # Attach a policy engine (module-managed by name, or an existing one by ARN)
    policy_engine_configuration = optional(object({
      policy_engine_name = optional(string)
      policy_engine_arn  = optional(string)
      mode               = optional(string, "ENFORCE") # "ENFORCE" or "LOG_ONLY"
    }))

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

  validation {
    condition = alltrue([
      for name, config in var.gateways :
      config.policy_engine_configuration == null || (
        (config.policy_engine_configuration.policy_engine_name != null) != (config.policy_engine_configuration.policy_engine_arn != null)
      )
    ])
    error_message = "policy_engine_configuration requires exactly one of policy_engine_name (a key of var.policy_engines) or policy_engine_arn."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateways :
      config.policy_engine_configuration == null || config.policy_engine_configuration.policy_engine_name == null || contains(keys(var.policy_engines), config.policy_engine_configuration.policy_engine_name)
    ])
    error_message = "policy_engine_configuration.policy_engine_name must reference a key of var.policy_engines."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateways :
      config.policy_engine_configuration == null || contains(["ENFORCE", "LOG_ONLY"], config.policy_engine_configuration.mode)
    ])
    error_message = "policy_engine_configuration.mode must be either 'ENFORCE' or 'LOG_ONLY'."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateways :
      contains(["MCP", "NONE"], config.protocol_type)
    ])
    error_message = "protocol_type must be 'MCP', or 'NONE' for a gateway that only has HTTP targets."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateways :
      config.protocol_type != "NONE" || config.protocol_configuration == null
    ])
    error_message = "protocol_configuration can only be set when protocol_type is MCP."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateways :
      config.protocol_type != "NONE" || (
        config.waf_configuration == null &&
        try(config.authorizer_configuration.custom_jwt_authorizer.advertised_scope_mapping, null) == null &&
        alltrue([for i in config.interceptor_configurations : i.input_configuration == null || length(i.input_configuration.exclude_fields) == 0])
      )
    ])
    error_message = "Gateways with protocol_type NONE are created with the aws provider resource, which does not support waf_configuration, advertised_scope_mapping or interceptor exclude_fields yet; leave those unset or use an MCP gateway."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateways :
      config.authorizer_type != "CUSTOM_JWT" || config.authorizer_configuration != null
    ])
    error_message = "authorizer_configuration.custom_jwt_authorizer is required when authorizer_type is CUSTOM_JWT."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateways :
      config.authorizer_configuration == null || (
        try(length(config.authorizer_configuration.custom_jwt_authorizer.allowed_audience), 0) +
        try(length(config.authorizer_configuration.custom_jwt_authorizer.allowed_clients), 0) +
        try(length(config.authorizer_configuration.custom_jwt_authorizer.allowed_scopes), 0) +
        length(config.authorizer_configuration.custom_jwt_authorizer.custom_claims)
      ) > 0
    ])
    error_message = "custom_jwt_authorizer needs at least one of allowed_audience, allowed_clients, allowed_scopes or custom_claims."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.gateways : [
        for claim in(config.authorizer_configuration == null ? [] : config.authorizer_configuration.custom_jwt_authorizer.custom_claims) :
        (claim.inbound_token_claim_value_type == "STRING" && claim.claim_match_operator == "EQUALS" && claim.match_value_string != null) ||
        (claim.inbound_token_claim_value_type == "STRING_ARRAY" && contains(["CONTAINS", "CONTAINS_ANY"], claim.claim_match_operator) && claim.match_value_string_list != null)
      ]
    ]))
    error_message = "custom_claims: STRING claims use claim_match_operator EQUALS with match_value_string; STRING_ARRAY claims use CONTAINS or CONTAINS_ANY with match_value_string_list."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateways :
      config.authorizer_configuration == null || config.authorizer_configuration.custom_jwt_authorizer.advertised_scope_mapping == null || alltrue([
        for scope in keys(config.authorizer_configuration.custom_jwt_authorizer.advertised_scope_mapping) :
        contains(try(config.authorizer_configuration.custom_jwt_authorizer.allowed_scopes, []), scope)
      ])
    ])
    error_message = "advertised_scope_mapping keys must be scopes listed in allowed_scopes."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateways :
      config.protocol_configuration == null || config.protocol_configuration.mcp.session_timeout_in_seconds == null || (
        config.protocol_configuration.mcp.session_timeout_in_seconds >= 900 && config.protocol_configuration.mcp.session_timeout_in_seconds <= 28800
      )
    ])
    error_message = "protocol_configuration.mcp.session_timeout_in_seconds must be between 900 and 28800."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateways :
      config.waf_configuration == null || contains(["FAIL_CLOSE", "FAIL_OPEN"], config.waf_configuration.failure_mode)
    ])
    error_message = "waf_configuration.failure_mode must be either 'FAIL_CLOSE' or 'FAIL_OPEN'."
  }
}

variable "gateway_targets" {
  description = "Map of AgentCore gateway targets to create. Each key is the target name. MCP targets (LAMBDA, MCP_SERVER) attach to MCP gateways; HTTP targets (AGENTCORE_RUNTIME, HTTP_PASSTHROUGH) attach to gateways with protocol_type NONE."
  type = map(object({
    gateway_name             = string
    description              = optional(string)
    credential_provider_type = optional(string) # "GATEWAY_IAM_ROLE", "API_KEY", "OAUTH", "JWT_PASSTHROUGH" or "CALLER_IAM_CREDENTIALS"

    # GATEWAY_IAM_ROLE: SigV4 signing of upstream requests (service is set to bedrock-agentcore for AGENTCORE_RUNTIME targets)
    gateway_iam_role_config = optional(object({
      service = optional(string)
      region  = optional(string)
    }))

    api_key_config = optional(object({
      provider_arn              = string
      credential_location       = string
      credential_parameter_name = string
      credential_prefix         = optional(string)
    }))

    oauth_config = optional(object({
      provider_arn       = string
      scopes             = optional(list(string))
      custom_parameters  = optional(map(string))
      grant_type         = optional(string) # "CLIENT_CREDENTIALS", "AUTHORIZATION_CODE" or "TOKEN_EXCHANGE"
      default_return_url = optional(string)
    }))

    # CALLER_IAM_CREDENTIALS: sign upstream requests with the caller's own identity
    caller_iam_config = optional(object({
      service = string
      region  = optional(string)
    }))

    type = string # "LAMBDA", "MCP_SERVER", "AGENTCORE_RUNTIME" or "HTTP_PASSTHROUGH"

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
      endpoint          = string
      listing_mode      = optional(string) # "DEFAULT" or "DYNAMIC"
      resource_priority = optional(number) # lower values win for shared resource URIs (service default 1000)

      # Static tool schema: disables dynamic tool discovery and synchronization
      tool_schema = optional(object({
        inline_payload             = optional(string) # JSON tool definitions
        s3_uri                     = optional(string)
        s3_bucket_owner_account_id = optional(string)
      }))
    }))

    # AGENTCORE_RUNTIME: route requests straight to a runtime (module-managed by name, or by ARN)
    agentcore_runtime_config = optional(object({
      runtime_name = optional(string)
      runtime_arn  = optional(string)
      qualifier    = optional(string) # runtime endpoint name (service default DEFAULT)

      # OpenAPI or Smithy schema; needed for guardrails on HTTP-protocol runtimes
      schema = optional(object({
        inline_payload             = optional(string)
        s3_uri                     = optional(string)
        s3_bucket_owner_account_id = optional(string)
      }))
    }))

    # HTTP_PASSTHROUGH: forward requests to an external HTTPS endpoint
    passthrough_config = optional(object({
      endpoint      = string
      protocol_type = string # "MCP", "A2A", "INFERENCE" or "CUSTOM"

      schema = optional(object({
        inline_payload             = optional(string)
        s3_uri                     = optional(string)
        s3_bucket_owner_account_id = optional(string)
      }))

      static_query_parameters                    = optional(map(string))
      static_query_parameter_conflict_resolution = optional(string) # "CLIENT_OVERRIDE" or "STATIC_OVERRIDE"

      stickiness_configuration = optional(object({
        identifier           = string # e.g. "$context.header.x-session-id"
        composite_identifier = optional(list(string))
        timeout              = optional(number) # seconds, 1-86400
      }))
    }))

    # Header and query parameter propagation between client, gateway and target (max 10 each)
    metadata_configuration = optional(object({
      allowed_request_headers  = optional(list(string))
      allowed_response_headers = optional(list(string))
      allowed_query_parameters = optional(list(string))
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

  validation {
    condition = alltrue([
      for name, config in var.gateway_targets :
      contains(["LAMBDA", "MCP_SERVER", "AGENTCORE_RUNTIME", "HTTP_PASSTHROUGH"], config.type)
    ])
    error_message = "Gateway target type must be one of: LAMBDA, MCP_SERVER, AGENTCORE_RUNTIME, HTTP_PASSTHROUGH."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateway_targets :
      contains(keys(var.gateways), config.gateway_name)
    ])
    error_message = "gateway_name must reference a key of var.gateways."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateway_targets :
      !contains(keys(var.gateways), config.gateway_name) || (
        contains(["LAMBDA", "MCP_SERVER"], config.type)
        ? var.gateways[config.gateway_name].protocol_type == "MCP"
        : var.gateways[config.gateway_name].protocol_type == "NONE"
      )
    ])
    error_message = "LAMBDA and MCP_SERVER targets need a gateway with protocol_type MCP; AGENTCORE_RUNTIME and HTTP_PASSTHROUGH targets need a gateway with protocol_type NONE."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateway_targets :
      (config.type != "LAMBDA" || config.lambda_config != null) &&
      (config.type != "MCP_SERVER" || config.mcp_server_config != null) &&
      (config.type != "AGENTCORE_RUNTIME" || config.agentcore_runtime_config != null) &&
      (config.type != "HTTP_PASSTHROUGH" || config.passthrough_config != null)
    ])
    error_message = "Each gateway target needs the configuration block matching its type (lambda_config, mcp_server_config, agentcore_runtime_config or passthrough_config)."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateway_targets :
      config.agentcore_runtime_config == null || (
        (config.agentcore_runtime_config.runtime_name != null) != (config.agentcore_runtime_config.runtime_arn != null)
      )
    ])
    error_message = "agentcore_runtime_config requires exactly one of runtime_name (a key of var.runtimes) or runtime_arn."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateway_targets :
      config.agentcore_runtime_config == null || config.agentcore_runtime_config.runtime_name == null || contains(keys(var.runtimes), config.agentcore_runtime_config.runtime_name)
    ])
    error_message = "agentcore_runtime_config.runtime_name must reference a key of var.runtimes."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateway_targets :
      config.passthrough_config == null || (
        contains(["MCP", "A2A", "INFERENCE", "CUSTOM"], config.passthrough_config.protocol_type) &&
        startswith(config.passthrough_config.endpoint, "https://") &&
        (config.passthrough_config.static_query_parameter_conflict_resolution == null || contains(["CLIENT_OVERRIDE", "STATIC_OVERRIDE"], config.passthrough_config.static_query_parameter_conflict_resolution)) &&
        (config.passthrough_config.stickiness_configuration == null || config.passthrough_config.stickiness_configuration.timeout == null || (config.passthrough_config.stickiness_configuration.timeout >= 1 && config.passthrough_config.stickiness_configuration.timeout <= 86400))
      )
    ])
    error_message = "passthrough_config: endpoint must start with https://, protocol_type must be MCP, A2A, INFERENCE or CUSTOM, static_query_parameter_conflict_resolution must be CLIENT_OVERRIDE or STATIC_OVERRIDE, and stickiness timeout must be between 1 and 86400 seconds."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateway_targets :
      config.mcp_server_config == null || (
        (config.mcp_server_config.listing_mode == null || contains(["DEFAULT", "DYNAMIC"], config.mcp_server_config.listing_mode)) &&
        (config.mcp_server_config.resource_priority == null || (config.mcp_server_config.resource_priority >= 0 && config.mcp_server_config.resource_priority <= 1000)) &&
        (config.mcp_server_config.tool_schema == null || (config.mcp_server_config.tool_schema.inline_payload != null) != (config.mcp_server_config.tool_schema.s3_uri != null))
      )
    ])
    error_message = "mcp_server_config: listing_mode must be DEFAULT or DYNAMIC, resource_priority must be between 0 and 1000, and tool_schema needs exactly one of inline_payload or s3_uri."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateway_targets :
      alltrue([
        for schema in [try(config.agentcore_runtime_config.schema, null), try(config.passthrough_config.schema, null)] :
        schema == null || (schema.inline_payload != null) != (schema.s3_uri != null)
      ])
    ])
    error_message = "A target schema needs exactly one of inline_payload or s3_uri."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateway_targets :
      config.credential_provider_type == null || contains(["GATEWAY_IAM_ROLE", "API_KEY", "OAUTH", "JWT_PASSTHROUGH", "CALLER_IAM_CREDENTIALS"], config.credential_provider_type)
    ])
    error_message = "credential_provider_type must be one of: GATEWAY_IAM_ROLE, API_KEY, OAUTH, JWT_PASSTHROUGH, CALLER_IAM_CREDENTIALS."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateway_targets :
      config.credential_provider_type != "CALLER_IAM_CREDENTIALS" || config.caller_iam_config != null
    ])
    error_message = "caller_iam_config (service, optional region) is required when credential_provider_type is CALLER_IAM_CREDENTIALS."
  }

  validation {
    condition = alltrue([
      for name, config in var.gateway_targets :
      config.metadata_configuration == null || alltrue([
        for headers in [config.metadata_configuration.allowed_request_headers, config.metadata_configuration.allowed_response_headers, config.metadata_configuration.allowed_query_parameters] :
        headers == null || length(headers) <= 10
      ])
    ])
    error_message = "metadata_configuration allows at most 10 request headers, 10 response headers and 10 query parameters per target."
  }
}

# – Agent Core Browsers –

variable "browsers" {
  description = "Map of AgentCore custom browsers to create. Each key is the browser name."
  type = map(object({
    description        = optional(string)
    execution_role_arn = optional(string)
    network_mode       = optional(string, "PUBLIC")

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
    description        = optional(string)
    execution_role_arn = optional(string)
    network_mode       = optional(string, "SANDBOX")

    network_configuration = optional(object({
      security_groups = list(string)
      subnets         = list(string)
    }))

    tags = optional(map(string))
  }))
  default = {}
}

# – Agent Core Workload Identities –

variable "workload_identities" {
  description = "Map of AgentCore workload identities to create. Each key is the workload identity name. Runtimes and gateways get a workload identity automatically; declare identities here for agents that run elsewhere or that need OAuth2 return URLs for 3-legged OAuth flows."
  type = map(object({
    allowed_resource_oauth2_return_urls = optional(list(string), [])
    tags                                = optional(map(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, config in var.workload_identities :
      can(regex("^[A-Za-z0-9][A-Za-z0-9._-]{0,254}$", name))
    ])
    error_message = "Workload identity names must be alphanumeric (plus ., _, -) and at most 255 characters."
  }
}

# – Agent Registry –

variable "registries" {
  description = "Map of AWS Agent Registry registries to create. Each key is the registry name. The module also creates an IAM policy (and optionally a role) that lets a publishing pipeline write and submit records; records can additionally be declared inline."
  type = map(object({
    description     = optional(string)
    authorizer_type = optional(string, "AWS_IAM") # "AWS_IAM" or "CUSTOM_JWT"

    authorizer_configuration = optional(object({
      custom_jwt_authorizer = object({
        discovery_url    = string
        allowed_audience = optional(list(string))
        allowed_clients  = optional(list(string))
        allowed_scopes   = optional(list(string))
      })
    }))

    auto_approve_records = optional(bool, false)
    kms_key_arn          = optional(string)

    auto_detection = optional(object({
      enabled = optional(bool, true)
      scope   = optional(string, "ORGANIZATION")
    }))

    custom_metadata_schema = optional(object({
      default_schema = optional(string) # JSON Schema document
      record_type_schema_overrides = optional(list(object({
        record_type = string
        schema      = string # JSON Schema document
      })), [])
    }))

    # IAM for the publisher (the pipeline or principal that writes records)
    publisher = optional(object({
      create_policy          = optional(bool, true)
      allow_approval         = optional(bool, false)
      trusted_principal_arns = optional(list(string), []) # IAM principals that may assume the publisher role
      trusted_services       = optional(list(string), []) # e.g. ["codebuild.amazonaws.com"]
    }), {})

    records = optional(map(object({
      record_type                    = string           # "MCP", "AGENT", "SKILL" or "CUSTOM"
      descriptor_type                = optional(string) # "MCP_SERVER", "A2A_AGENT_CARD", "AGENT_SKILLS_DEFINITION" or "CUSTOM" (defaults by record_type)
      description                    = optional(string)
      display_name                   = optional(string)
      record_version                 = optional(string)
      descriptor_data                = optional(string) # JSON document (MCP server.json, A2A agent card, skill definition or custom payload)
      descriptor_data_schema_version = optional(string)
      descriptor_source_url          = optional(string) # synchronize the descriptor from a URL instead of inline data
      tools_data                     = optional(string) # MCP only: tools JSON document
      tools_data_schema_version      = optional(string)
      custom_metadata                = optional(string) # JSON object matching the registry's custom metadata schema
      tags                           = optional(map(string))
    })), {})

    tags = optional(map(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, config in var.registries :
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,99}$", name))
    ])
    error_message = "Registry names must start with a letter or number and contain only letters, numbers, '.', '_' and '-' (max 100 characters; '/' is valid for the service but not in the IAM policy names derived from it)."
  }

  validation {
    condition = alltrue([
      for name, config in var.registries :
      contains(["AWS_IAM", "CUSTOM_JWT"], config.authorizer_type)
    ])
    error_message = "Registry authorizer_type must be either 'AWS_IAM' or 'CUSTOM_JWT'."
  }

  validation {
    condition = alltrue([
      for name, config in var.registries :
      config.authorizer_type != "CUSTOM_JWT" || config.authorizer_configuration != null
    ])
    error_message = "authorizer_configuration.custom_jwt_authorizer is required when authorizer_type is CUSTOM_JWT."
  }

  validation {
    condition = alltrue([
      for name, config in var.registries :
      config.auto_detection == null || config.auto_detection.scope == "ORGANIZATION"
    ])
    error_message = "auto_detection.scope must be 'ORGANIZATION' (the only scope the service supports)."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.registries : [
        for record_name, record in config.records :
        contains(["MCP", "AGENT", "SKILL", "CUSTOM"], record.record_type)
      ]
    ]))
    error_message = "Registry record record_type must be one of: MCP, AGENT, SKILL, CUSTOM."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.registries : [
        for record_name, record in config.records :
        record.descriptor_type == null || contains(["MCP_SERVER", "A2A_AGENT_CARD", "AGENT_SKILLS_DEFINITION", "CUSTOM"], record.descriptor_type)
      ]
    ]))
    error_message = "Registry record descriptor_type must be one of: MCP_SERVER, A2A_AGENT_CARD, AGENT_SKILLS_DEFINITION, CUSTOM."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.registries : [
        for record_name, record in config.records :
        record.descriptor_data != null || record.descriptor_source_url != null
      ]
    ]))
    error_message = "Registry records need descriptor_data (inline JSON) or descriptor_source_url."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.registries : [
        for record_name, record in config.records :
        can(regex("^[a-zA-Z0-9][a-zA-Z0-9_\\-\\./]*$", record_name))
      ]
    ]))
    error_message = "Registry record names must start with a letter or number and contain only letters, numbers, '_', '-', '.' and '/'."
  }
}

# – Agent Core Policy –

variable "policy_engines" {
  description = "Map of AgentCore policy engines to create. Each key is the policy engine name. Attach an engine to a gateway with the gateway's policy_engine_configuration. Statements may use {{gateway:<name>}}, {{target:<name>}} and {{runtime:<name>}} placeholders, which resolve to resources created by this module."
  type = map(object({
    description        = optional(string)
    encryption_key_arn = optional(string)

    policies = optional(list(object({
      name             = string
      description      = optional(string)
      statement        = string                                   # Cedar or Dogwood policy text
      language         = optional(string, "CEDAR")                # "CEDAR" or "DOGWOOD" (temporal rules, guardrails)
      enforcement_mode = optional(string, "ACTIVE")               # "ACTIVE" or "LOG_ONLY"
      validation_mode  = optional(string, "FAIL_ON_ANY_FINDINGS") # "FAIL_ON_ANY_FINDINGS" or "IGNORE_ALL_FINDINGS"
    })), [])

    tags = optional(map(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, config in var.policy_engines :
      can(regex("^[A-Za-z][A-Za-z0-9_]{0,47}$", name))
    ])
    error_message = "Policy engine names must start with a letter and contain only letters, numbers, and underscores (max 48 characters, no hyphens)."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.policy_engines : [
        for policy in config.policies :
        can(regex("^[A-Za-z][A-Za-z0-9_]{0,47}$", policy.name))
      ]
    ]))
    error_message = "Policy names must start with a letter and contain only letters, numbers, and underscores (max 48 characters, no hyphens)."
  }

  validation {
    condition = alltrue([
      for name, config in var.policy_engines :
      length(distinct([for policy in config.policies : policy.name])) == length(config.policies)
    ])
    error_message = "Policy names must be unique within a policy engine."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.policy_engines : [
        for policy in config.policies :
        contains(["CEDAR", "DOGWOOD"], policy.language)
      ]
    ]))
    error_message = "Policy language must be either 'CEDAR' or 'DOGWOOD'."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.policy_engines : [
        for policy in config.policies :
        contains(["ACTIVE", "LOG_ONLY"], policy.enforcement_mode)
      ]
    ]))
    error_message = "Policy enforcement_mode must be either 'ACTIVE' or 'LOG_ONLY'."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.policy_engines : [
        for policy in config.policies :
        contains(["FAIL_ON_ANY_FINDINGS", "IGNORE_ALL_FINDINGS"], policy.validation_mode)
      ]
    ]))
    error_message = "Policy validation_mode must be either 'FAIL_ON_ANY_FINDINGS' or 'IGNORE_ALL_FINDINGS'."
  }
}

# – Agent Core Configuration Bundles –

variable "configuration_bundles" {
  description = "Map of AgentCore configuration bundles to create. Each key is the bundle name. components maps a component identifier (an AgentCore resource ARN, or a {{runtime:<name>}} / {{gateway:<name>}} placeholder for a resource created by this module) to its configuration object, which is stored as JSON."
  type = map(object({
    description    = optional(string)
    branch_name    = optional(string) # defaults to "mainline"
    commit_message = optional(string)
    kms_key_arn    = optional(string)
    components     = any # map of component identifier => configuration object
    tags           = optional(map(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, config in var.configuration_bundles :
      can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,99}$", name))
    ])
    error_message = "Configuration bundle names must start with a letter and contain only letters, numbers, and underscores (max 100 characters, no hyphens)."
  }

  validation {
    condition = alltrue([
      for name, config in var.configuration_bundles :
      can(keys(config.components)) && length(keys(config.components)) > 0
    ])
    error_message = "Each configuration bundle needs at least one component (a map of component identifier => configuration object)."
  }
}
