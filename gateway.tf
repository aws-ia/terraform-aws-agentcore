# ═══════════════════════════════════════════════════════════════════════════
# BEDROCK AGENTCORE GATEWAYS & GATEWAY TARGETS
# ═══════════════════════════════════════════════════════════════════════════

# ─── Gateways ───

# MCP gateways (protocol_type = "MCP", the default). Gateways that front HTTP targets
# (protocol_type = "NONE") are created below with the aws provider resource, because
# the CloudFormation-based awscc resource always ends up with the MCP protocol type.
resource "awscc_bedrockagentcore_gateway" "gateway" {
  for_each = {
    for name, config in var.gateways :
    name => config
    if config.protocol_type != "NONE"
  }

  name            = each.key
  description     = each.value.description
  role_arn        = each.value.role_arn != null ? each.value.role_arn : aws_iam_role.gateway[each.key].arn
  authorizer_type = each.value.authorizer_type
  protocol_type   = each.value.protocol_type
  exception_level = each.value.exception_level
  kms_key_arn     = each.value.kms_key_arn

  authorizer_configuration = local.gateway_authorizer_configurations[each.key]

  protocol_configuration = each.value.protocol_configuration != null ? {
    mcp = {
      instructions       = each.value.protocol_configuration.mcp.instructions
      search_type        = each.value.protocol_configuration.mcp.search_type
      supported_versions = each.value.protocol_configuration.mcp.supported_versions
      session_configuration = each.value.protocol_configuration.mcp.session_timeout_in_seconds != null ? {
        session_timeout_in_seconds = each.value.protocol_configuration.mcp.session_timeout_in_seconds
      } : null
      streaming_configuration = each.value.protocol_configuration.mcp.enable_response_streaming != null ? {
        enable_response_streaming = each.value.protocol_configuration.mcp.enable_response_streaming
      } : null
    }
  } : null

  interceptor_configurations = length(each.value.interceptor_configurations) > 0 ? [
    for config in each.value.interceptor_configurations : {
      interception_points = config.interception_points
      interceptor = {
        lambda = {
          arn = config.interceptor.lambda.arn
        }
      }
      input_configuration = config.input_configuration != null ? {
        pass_request_headers = config.input_configuration.pass_request_headers
        payload_filter = length(config.input_configuration.exclude_fields) > 0 ? {
          exclude = [for field in config.input_configuration.exclude_fields : { field = field }]
        } : null
      } : null
    }
  ] : null

  # AWS WAF failure mode (the web ACL itself is associated below)
  waf_configuration = each.value.waf_configuration != null ? {
    failure_mode = each.value.waf_configuration.failure_mode
  } : null

  # Policy engine attachment (ENFORCE or LOG_ONLY). The gateway role needs the
  # policy engine permissions (see iam.tf) before the engine can be attached.
  policy_engine_configuration = each.value.policy_engine_configuration != null ? {
    arn  = local.gateway_policy_engine_arns[each.key]
    mode = each.value.policy_engine_configuration.mode
  } : null

  tags = merge(local.merged_tags, each.value.tags)

  depends_on = [time_sleep.gateway_iam_policy_propagation]
}

# ─── Gateways without a protocol type (HTTP targets: AgentCore Runtime, passthrough) ───

resource "aws_bedrockagentcore_gateway" "gateway_http" {
  for_each = {
    for name, config in var.gateways :
    name => config
    if config.protocol_type == "NONE"
  }

  name            = each.key
  description     = each.value.description
  role_arn        = each.value.role_arn != null ? each.value.role_arn : aws_iam_role.gateway[each.key].arn
  authorizer_type = each.value.authorizer_type
  exception_level = each.value.exception_level
  kms_key_arn     = each.value.kms_key_arn

  dynamic "authorizer_configuration" {
    for_each = each.value.authorizer_type == "CUSTOM_JWT" && each.value.authorizer_configuration != null ? [each.value.authorizer_configuration.custom_jwt_authorizer] : []
    content {
      custom_jwt_authorizer {
        discovery_url    = authorizer_configuration.value.discovery_url
        allowed_audience = authorizer_configuration.value.allowed_audience
        allowed_clients  = authorizer_configuration.value.allowed_clients
        allowed_scopes   = authorizer_configuration.value.allowed_scopes

        dynamic "custom_claim" {
          for_each = authorizer_configuration.value.custom_claims
          content {
            inbound_token_claim_name       = custom_claim.value.inbound_token_claim_name
            inbound_token_claim_value_type = custom_claim.value.inbound_token_claim_value_type
            authorizing_claim_match_value {
              claim_match_operator = custom_claim.value.claim_match_operator
              claim_match_value {
                match_value_string      = custom_claim.value.match_value_string
                match_value_string_list = custom_claim.value.match_value_string_list
              }
            }
          }
        }
      }
    }
  }

  dynamic "interceptor_configuration" {
    for_each = each.value.interceptor_configurations
    content {
      interception_points = interceptor_configuration.value.interception_points
      interceptor {
        lambda {
          arn = interceptor_configuration.value.interceptor.lambda.arn
        }
      }
      input_configuration {
        pass_request_headers = interceptor_configuration.value.input_configuration != null ? interceptor_configuration.value.input_configuration.pass_request_headers : false
      }
    }
  }

  dynamic "policy_engine_configuration" {
    for_each = each.value.policy_engine_configuration != null ? [1] : []
    content {
      arn  = local.gateway_policy_engine_arns[each.key]
      mode = each.value.policy_engine_configuration.mode
    }
  }

  tags = merge(local.merged_tags, each.value.tags)

  depends_on = [time_sleep.gateway_iam_policy_propagation]
}

# ─── AWS WAF web ACL association ───
# One regional web ACL per gateway. The caller needs wafv2:AssociateWebACL and
# bedrock-agentcore:GatewayAssociateWebACL (and the Disassociate counterparts).

resource "aws_wafv2_web_acl_association" "gateway" {
  for_each = {
    for name, config in var.gateways :
    name => config
    if config.waf_configuration != null && config.waf_configuration.web_acl_arn != null
  }

  resource_arn = local.gateway_arns[each.key]
  web_acl_arn  = each.value.waf_configuration.web_acl_arn
}

# ─── Gateway Targets ───

resource "aws_bedrockagentcore_gateway_target" "gateway_target" {
  for_each = var.gateway_targets

  name               = "${var.project_prefix}-${each.key}"
  gateway_identifier = local.gateway_identifiers[each.value.gateway_name]
  description        = each.value.description

  depends_on = [
    awscc_bedrockagentcore_gateway.gateway,
    aws_bedrockagentcore_gateway.gateway_http,
    aws_iam_role_policy.gateway_role_policy,
    time_sleep.gateway_iam_policy_propagation
  ]

  # AgentCore Runtime targets are always invoked with the gateway role: the service fills
  # that default in when the block is omitted (which the provider then reports as an
  # inconsistent result) and rejects a SigV4 service on it, so the module sends an empty
  # gateway_iam_role block for them unless another credential type is chosen.
  dynamic "credential_provider_configuration" {
    for_each = each.value.credential_provider_type != null || each.value.type == "AGENTCORE_RUNTIME" ? [1] : []

    content {
      # SigV4 with the gateway role; service/region only for SigV4-protected passthrough endpoints
      dynamic "gateway_iam_role" {
        for_each = each.value.credential_provider_type == "GATEWAY_IAM_ROLE" || (each.value.type == "AGENTCORE_RUNTIME" && each.value.credential_provider_type == null) ? [1] : []
        content {
          service = try(each.value.gateway_iam_role_config.service, null)
          region  = try(each.value.gateway_iam_role_config.region, null)
        }
      }

      dynamic "api_key" {
        for_each = each.value.credential_provider_type == "API_KEY" && each.value.api_key_config != null ? [1] : []
        content {
          provider_arn              = each.value.api_key_config.provider_arn
          credential_location       = each.value.api_key_config.credential_location
          credential_parameter_name = each.value.api_key_config.credential_parameter_name
          credential_prefix         = each.value.api_key_config.credential_prefix
        }
      }

      dynamic "oauth" {
        for_each = each.value.credential_provider_type == "OAUTH" && each.value.oauth_config != null ? [1] : []
        content {
          provider_arn       = each.value.oauth_config.provider_arn
          scopes             = each.value.oauth_config.scopes
          custom_parameters  = each.value.oauth_config.custom_parameters
          grant_type         = each.value.oauth_config.grant_type
          default_return_url = each.value.oauth_config.default_return_url
        }
      }

      # Forward the validated inbound JWT to the target unchanged
      dynamic "jwt_passthrough" {
        for_each = each.value.credential_provider_type == "JWT_PASSTHROUGH" ? [1] : []
        content {}
      }

      dynamic "caller_iam_credentials" {
        for_each = each.value.credential_provider_type == "CALLER_IAM_CREDENTIALS" && each.value.caller_iam_config != null ? [1] : []
        content {
          service = each.value.caller_iam_config.service
          region  = each.value.caller_iam_config.region
        }
      }
    }
  }

  dynamic "metadata_configuration" {
    for_each = each.value.metadata_configuration != null ? [1] : []
    content {
      allowed_request_headers  = each.value.metadata_configuration.allowed_request_headers
      allowed_response_headers = each.value.metadata_configuration.allowed_response_headers
      allowed_query_parameters = each.value.metadata_configuration.allowed_query_parameters
    }
  }

  target_configuration {
    # MCP targets (gateway protocol_type MCP): Lambda tools and MCP servers
    dynamic "mcp" {
      for_each = contains(["LAMBDA", "MCP_SERVER"], each.value.type) ? [1] : []
      content {
        dynamic "lambda" {
          for_each = each.value.type == "LAMBDA" && each.value.lambda_config != null ? [1] : []
          content {
            lambda_arn = each.value.lambda_config.lambda_arn

            tool_schema {
              dynamic "inline_payload" {
                for_each = each.value.lambda_config.tool_schema_type == "INLINE" && each.value.lambda_config.inline_schema != null ? [1] : []
                content {
                  name        = each.value.lambda_config.inline_schema.name
                  description = each.value.lambda_config.inline_schema.description

                  input_schema {
                    type        = each.value.lambda_config.inline_schema.input_schema.type
                    description = each.value.lambda_config.inline_schema.input_schema.description

                    dynamic "property" {
                      for_each = each.value.lambda_config.inline_schema.input_schema.type == "object" && each.value.lambda_config.inline_schema.input_schema.properties != null ? each.value.lambda_config.inline_schema.input_schema.properties : []
                      content {
                        name        = property.value.name
                        type        = property.value.type
                        description = lookup(property.value, "description", null)
                        required    = lookup(property.value, "required", false)

                        dynamic "property" {
                          for_each = property.value.type == "object" && lookup(property.value, "nested_properties", null) != null ? property.value.nested_properties : []
                          content {
                            name        = property.value.name
                            type        = property.value.type
                            description = lookup(property.value, "description", null)
                            required    = lookup(property.value, "required", false)
                          }
                        }

                        dynamic "items" {
                          for_each = property.value.type == "array" && lookup(property.value, "items", null) != null ? [property.value.items] : []
                          content {
                            type        = items.value.type
                            description = lookup(items.value, "description", null)
                          }
                        }
                      }
                    }

                    dynamic "items" {
                      for_each = each.value.lambda_config.inline_schema.input_schema.type == "array" && lookup(each.value.lambda_config.inline_schema.input_schema, "items", null) != null ? [each.value.lambda_config.inline_schema.input_schema.items] : []
                      content {
                        type        = items.value.type
                        description = lookup(items.value, "description", null)
                      }
                    }
                  }

                  dynamic "output_schema" {
                    for_each = each.value.lambda_config.inline_schema.output_schema != null ? [each.value.lambda_config.inline_schema.output_schema] : []
                    content {
                      type        = output_schema.value.type
                      description = lookup(output_schema.value, "description", null)

                      dynamic "property" {
                        for_each = output_schema.value.type == "object" && lookup(output_schema.value, "properties", null) != null ? output_schema.value.properties : []
                        content {
                          name        = property.value.name
                          type        = property.value.type
                          description = lookup(property.value, "description", null)
                          required    = lookup(property.value, "required", false)
                        }
                      }

                      dynamic "items" {
                        for_each = output_schema.value.type == "array" && lookup(output_schema.value, "items", null) != null ? [output_schema.value.items] : []
                        content {
                          type        = items.value.type
                          description = lookup(items.value, "description", null)
                        }
                      }
                    }
                  }
                }
              }

              dynamic "s3" {
                for_each = each.value.lambda_config.tool_schema_type == "S3" && each.value.lambda_config.s3_schema != null ? [1] : []
                content {
                  uri                     = each.value.lambda_config.s3_schema.uri
                  bucket_owner_account_id = lookup(each.value.lambda_config.s3_schema, "bucket_owner_account_id", null)
                }
              }
            }
          }
        }

        dynamic "mcp_server" {
          for_each = each.value.type == "MCP_SERVER" && each.value.mcp_server_config != null ? [1] : []
          content {
            endpoint          = each.value.mcp_server_config.endpoint
            listing_mode      = each.value.mcp_server_config.listing_mode
            resource_priority = each.value.mcp_server_config.resource_priority

            # Static tool schema: no dynamic discovery or synchronization for this target
            dynamic "mcp_tool_schema" {
              for_each = each.value.mcp_server_config.tool_schema != null ? [1] : []
              content {
                dynamic "inline_payload" {
                  for_each = each.value.mcp_server_config.tool_schema.inline_payload != null ? [1] : []
                  content {
                    payload = each.value.mcp_server_config.tool_schema.inline_payload
                  }
                }

                dynamic "s3" {
                  for_each = each.value.mcp_server_config.tool_schema.s3_uri != null ? [1] : []
                  content {
                    uri                     = each.value.mcp_server_config.tool_schema.s3_uri
                    bucket_owner_account_id = each.value.mcp_server_config.tool_schema.s3_bucket_owner_account_id
                  }
                }
              }
            }
          }
        }
      }
    }

    # HTTP targets (gateway protocol_type NONE): AgentCore Runtime and passthrough
    dynamic "http" {
      for_each = contains(["AGENTCORE_RUNTIME", "HTTP_PASSTHROUGH"], each.value.type) ? [1] : []
      content {
        dynamic "agentcore_runtime" {
          for_each = each.value.type == "AGENTCORE_RUNTIME" && each.value.agentcore_runtime_config != null ? [1] : []
          content {
            arn       = local.gateway_target_runtime_arns[each.key]
            qualifier = each.value.agentcore_runtime_config.qualifier

            dynamic "schema" {
              for_each = each.value.agentcore_runtime_config.schema != null ? [1] : []
              content {
                source {
                  dynamic "inline_payload" {
                    for_each = each.value.agentcore_runtime_config.schema.inline_payload != null ? [1] : []
                    content {
                      payload = each.value.agentcore_runtime_config.schema.inline_payload
                    }
                  }

                  dynamic "s3" {
                    for_each = each.value.agentcore_runtime_config.schema.s3_uri != null ? [1] : []
                    content {
                      uri                     = each.value.agentcore_runtime_config.schema.s3_uri
                      bucket_owner_account_id = each.value.agentcore_runtime_config.schema.s3_bucket_owner_account_id
                    }
                  }
                }
              }
            }
          }
        }

        dynamic "passthrough" {
          for_each = each.value.type == "HTTP_PASSTHROUGH" && each.value.passthrough_config != null ? [1] : []
          content {
            endpoint                                   = each.value.passthrough_config.endpoint
            protocol_type                              = each.value.passthrough_config.protocol_type
            static_query_parameters                    = each.value.passthrough_config.static_query_parameters
            static_query_parameter_conflict_resolution = each.value.passthrough_config.static_query_parameter_conflict_resolution

            dynamic "schema" {
              for_each = each.value.passthrough_config.schema != null ? [1] : []
              content {
                source {
                  dynamic "inline_payload" {
                    for_each = each.value.passthrough_config.schema.inline_payload != null ? [1] : []
                    content {
                      payload = each.value.passthrough_config.schema.inline_payload
                    }
                  }

                  dynamic "s3" {
                    for_each = each.value.passthrough_config.schema.s3_uri != null ? [1] : []
                    content {
                      uri                     = each.value.passthrough_config.schema.s3_uri
                      bucket_owner_account_id = each.value.passthrough_config.schema.s3_bucket_owner_account_id
                    }
                  }
                }
              }
            }

            dynamic "stickiness_configuration" {
              for_each = each.value.passthrough_config.stickiness_configuration != null ? [1] : []
              content {
                identifier           = each.value.passthrough_config.stickiness_configuration.identifier
                composite_identifier = each.value.passthrough_config.stickiness_configuration.composite_identifier
                timeout              = each.value.passthrough_config.stickiness_configuration.timeout
              }
            }
          }
        }
      }
    }
  }
}
