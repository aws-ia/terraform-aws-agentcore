# – Bedrock Agent Core Gateway Target –

locals {
  create_gateway_target = var.create_gateway_target
}

resource "aws_bedrockagentcore_gateway_target" "gateway_target" {
  count = local.create_gateway_target ? 1 : 0

  name               = "${random_string.solution_prefix.result}-${var.gateway_target_name}"
  gateway_identifier = var.gateway_target_gateway_id != null ? var.gateway_target_gateway_id : try(awscc_bedrockagentcore_gateway.agent_gateway[0].gateway_identifier, null)
  description        = var.gateway_target_description

  # Make sure the gateway and IAM role are created first
  depends_on = [
    awscc_bedrockagentcore_gateway.agent_gateway,
    aws_iam_role_policy.gateway_role_policy
  ]

  # Credential provider configuration
  dynamic "credential_provider_configuration" {
    for_each = var.gateway_target_credential_provider_type != null ? [1] : []

    content {
      dynamic "gateway_iam_role" {
        for_each = var.gateway_target_credential_provider_type == "GATEWAY_IAM_ROLE" ? [1] : []
        content {}
      }

      dynamic "api_key" {
        for_each = var.gateway_target_credential_provider_type == "API_KEY" && var.gateway_target_api_key_config != null ? [1] : []

        content {
          provider_arn              = var.gateway_target_api_key_config.provider_arn
          credential_location       = var.gateway_target_api_key_config.credential_location
          credential_parameter_name = var.gateway_target_api_key_config.credential_parameter_name
          credential_prefix         = var.gateway_target_api_key_config.credential_prefix
        }
      }

      dynamic "oauth" {
        for_each = var.gateway_target_credential_provider_type == "OAUTH" && var.gateway_target_oauth_config != null ? [1] : []

        content {
          provider_arn      = var.gateway_target_oauth_config.provider_arn
          scopes            = var.gateway_target_oauth_config.scopes
          custom_parameters = var.gateway_target_oauth_config.custom_parameters
        }
      }
    }
  }

  # Target configuration
  target_configuration {
    mcp {
      dynamic "lambda" {
        for_each = var.gateway_target_type == "LAMBDA" && var.gateway_target_lambda_config != null ? [1] : []

        content {
          lambda_arn = var.gateway_target_lambda_config.lambda_arn

          tool_schema {
            dynamic "inline_payload" {
              for_each = var.gateway_target_lambda_config.tool_schema_type == "INLINE" && var.gateway_target_lambda_config.inline_schema != null ? [1] : []

              content {
                name        = var.gateway_target_lambda_config.inline_schema.name
                description = var.gateway_target_lambda_config.inline_schema.description

                # Input schema
                input_schema {
                  type        = var.gateway_target_lambda_config.inline_schema.input_schema.type
                  description = var.gateway_target_lambda_config.inline_schema.input_schema.description

                  # Properties for object type
                  dynamic "property" {
                    for_each = var.gateway_target_lambda_config.inline_schema.input_schema.type == "object" && var.gateway_target_lambda_config.inline_schema.input_schema.properties != null ? var.gateway_target_lambda_config.inline_schema.input_schema.properties : []

                    content {
                      name        = property.value.name
                      type        = property.value.type
                      description = lookup(property.value, "description", null)
                      required    = lookup(property.value, "required", false)

                      # Nested properties for object properties
                      dynamic "property" {
                        for_each = property.value.type == "object" && lookup(property.value, "nested_properties", null) != null ? property.value.nested_properties : []

                        content {
                          name        = property.value.name
                          type        = property.value.type
                          description = lookup(property.value, "description", null)
                          required    = lookup(property.value, "required", false)
                        }
                      }

                      # Items for array properties
                      dynamic "items" {
                        for_each = property.value.type == "array" && lookup(property.value, "items", null) != null ? [property.value.items] : []

                        content {
                          type        = items.value.type
                          description = lookup(items.value, "description", null)
                        }
                      }
                    }
                  }

                  # Items for array type
                  dynamic "items" {
                    for_each = var.gateway_target_lambda_config.inline_schema.input_schema.type == "array" && lookup(var.gateway_target_lambda_config.inline_schema.input_schema, "items", null) != null ? [var.gateway_target_lambda_config.inline_schema.input_schema.items] : []

                    content {
                      type        = items.value.type
                      description = lookup(items.value, "description", null)
                    }
                  }
                }

                # Output schema (optional)
                dynamic "output_schema" {
                  for_each = var.gateway_target_lambda_config.inline_schema.output_schema != null ? [var.gateway_target_lambda_config.inline_schema.output_schema] : []

                  content {
                    type        = output_schema.value.type
                    description = lookup(output_schema.value, "description", null)

                    # Properties for object type output
                    dynamic "property" {
                      for_each = output_schema.value.type == "object" && lookup(output_schema.value, "properties", null) != null ? output_schema.value.properties : []

                      content {
                        name        = property.value.name
                        type        = property.value.type
                        description = lookup(property.value, "description", null)
                        required    = lookup(property.value, "required", false)
                      }
                    }

                    # Items for array type output
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
              for_each = var.gateway_target_lambda_config.tool_schema_type == "S3" && var.gateway_target_lambda_config.s3_schema != null ? [1] : []

              content {
                uri                     = var.gateway_target_lambda_config.s3_schema.uri
                bucket_owner_account_id = lookup(var.gateway_target_lambda_config.s3_schema, "bucket_owner_account_id", null)
              }
            }
          }
        }
      }

      dynamic "mcp_server" {
        for_each = var.gateway_target_type == "MCP_SERVER" && var.gateway_target_mcp_server_config != null ? [1] : []

        content {
          endpoint = var.gateway_target_mcp_server_config.endpoint
        }
      }
    }
  }
}
