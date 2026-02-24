# ═══════════════════════════════════════════════════════════════════════════
# BEDROCK AGENTCORE GATEWAYS & GATEWAY TARGETS
# ═══════════════════════════════════════════════════════════════════════════

# ─── Gateways ───

resource "awscc_bedrockagentcore_gateway" "gateway" {
  for_each = var.gateways

  name            = each.key
  description     = each.value.description
  role_arn        = each.value.role_arn != null ? each.value.role_arn : aws_iam_role.gateway[each.key].arn
  authorizer_type = each.value.authorizer_type
  protocol_type   = each.value.protocol_type
  exception_level = each.value.exception_level
  kms_key_arn     = each.value.kms_key_arn

  authorizer_configuration = each.value.authorizer_type == "CUSTOM_JWT" && each.value.authorizer_configuration != null ? {
    custom_jwt_authorizer = {
      allowed_audience = each.value.authorizer_configuration.custom_jwt_authorizer.allowed_audience
      allowed_clients  = each.value.authorizer_configuration.custom_jwt_authorizer.allowed_clients
      discovery_url    = each.value.authorizer_configuration.custom_jwt_authorizer.discovery_url
    }
  } : null

  protocol_configuration = each.value.protocol_configuration != null ? {
    mcp = {
      instructions       = each.value.protocol_configuration.mcp.instructions
      search_type        = each.value.protocol_configuration.mcp.search_type
      supported_versions = each.value.protocol_configuration.mcp.supported_versions
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
      } : null
    }
  ] : null

  tags = merge(local.merged_tags, each.value.tags)
}

# ─── Gateway Targets ───

resource "aws_bedrockagentcore_gateway_target" "gateway_target" {
  for_each = var.gateway_targets

  name               = "${var.project_prefix}-${each.key}"
  gateway_identifier = awscc_bedrockagentcore_gateway.gateway[each.value.gateway_name].gateway_identifier
  description        = each.value.description

  depends_on = [
    awscc_bedrockagentcore_gateway.gateway,
    aws_iam_role_policy.gateway_role_policy,
    time_sleep.gateway_iam_policy_propagation
  ]

  dynamic "credential_provider_configuration" {
    for_each = each.value.credential_provider_type != null ? [1] : []

    content {
      dynamic "gateway_iam_role" {
        for_each = each.value.credential_provider_type == "GATEWAY_IAM_ROLE" ? [1] : []
        content {}
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
          provider_arn      = each.value.oauth_config.provider_arn
          scopes            = each.value.oauth_config.scopes
          custom_parameters = each.value.oauth_config.custom_parameters
        }
      }
    }
  }

  target_configuration {
    mcp {
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
          endpoint = each.value.mcp_server_config.endpoint
        }
      }

      dynamic "open_api_schema" {
        for_each = each.value.type == "OPEN_API_SCHEMA" && each.value.open_api_schema_config != null ? [1] : []

        content {
          dynamic "inline_payload" {
            for_each = each.value.open_api_schema_config.inline_payload != null ? [1] : []
            content {
              payload = each.value.open_api_schema_config.inline_payload.payload
            }
          }
          dynamic "s3" {
            for_each = each.value.open_api_schema_config.s3 != null ? [1] : []
            content {
              uri                     = each.value.open_api_schema_config.s3.uri
              bucket_owner_account_id = each.value.open_api_schema_config.s3.bucket_owner_account_id
            }
          }
        }
      }

      dynamic "smithy_model" {
        for_each = each.value.type == "SMITHY_MODEL" && each.value.smithy_model_config != null ? [1] : []

        content {
          dynamic "inline_payload" {
            for_each = each.value.smithy_model_config.inline_payload != null ? [1] : []
            content {
              payload = each.value.smithy_model_config.inline_payload.payload
            }
          }
          dynamic "s3" {
            for_each = each.value.smithy_model_config.s3 != null ? [1] : []
            content {
              uri                     = each.value.smithy_model_config.s3.uri
              bucket_owner_account_id = each.value.smithy_model_config.s3.bucket_owner_account_id
            }
          }
        }
      }
    }
  }
}
