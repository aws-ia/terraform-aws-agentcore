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

variable "runtime_container_uri" {
  description = "The ECR URI of the container for the agent core runtime."
  type        = string
  default     = null
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
    condition     = var.gateway_exception_level == null || contains(["PARTIAL", "FULL"], var.gateway_exception_level)
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
