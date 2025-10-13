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
  description = "value"
  type        = object({
    security_groups = optional(list(string))
    subnets         = optional(list(string))
  })
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
  description = "The authorizer type for the gateway. Valid values: NONE, CUSTOM_JWT."
  type        = string
  default     = "NONE"
  
  validation {
    condition     = contains(["NONE", "CUSTOM_JWT"], var.gateway_authorizer_type)
    error_message = "The gateway_authorizer_type must be either NONE or CUSTOM_JWT."
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
  default     = true
}

# - IAM -
variable "permissions_boundary_arn" {
  description = "The ARN of the IAM permission boundary for the role."
  type        = string
  default     = null
}