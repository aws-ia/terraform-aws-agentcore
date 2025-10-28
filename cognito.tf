# – Cognito User Pool for JWT Authentication Fallback –

locals {
  # Create User Pool when JWT auth info is not provided but gateway with JWT auth is requested
  create_user_pool = local.create_gateway && var.gateway_authorizer_type == "CUSTOM_JWT" && var.gateway_authorizer_configuration == null

  # Define domain name for the User Pool
  user_pool_domain_name = lower("${random_string.solution_prefix.result}-${var.user_pool_name}")

  # If User Pool is created, set the discovery URL for the gateway authorizer
  gateway_authorizer_config = local.create_user_pool ? {
    custom_jwt_authorizer = {
      discovery_url    = "https://cognito-idp.${data.aws_region.current.region}.amazonaws.com/${aws_cognito_user_pool.default[0].id}/.well-known/openid-configuration"
      allowed_audience = [aws_cognito_user_pool_client.default[0].id]
      allowed_clients  = length(var.user_pool_allowed_clients) > 0 ? var.user_pool_allowed_clients : [aws_cognito_user_pool_client.default[0].id]
    }
  } : var.gateway_authorizer_configuration
}

resource "random_password" "password" {
  count = local.create_user_pool && var.user_pool_create_admin ? 1 : 0
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Cognito User Pool
resource "aws_cognito_user_pool" "default" {
  count = local.create_user_pool ? 1 : 0

  name = "${random_string.solution_prefix.result}_${var.user_pool_name}"
  username_configuration {
    case_sensitive = false
  }

  # Configure password policy
  password_policy {
    minimum_length    = var.user_pool_password_policy.minimum_length
    require_lowercase = var.user_pool_password_policy.require_lowercase
    require_numbers   = var.user_pool_password_policy.require_numbers
    require_symbols   = var.user_pool_password_policy.require_symbols
    require_uppercase = var.user_pool_password_policy.require_uppercase
  }

  # Configure MFA
  mfa_configuration = var.user_pool_mfa_configuration

  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Configure schema attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true
  }

  # Auto-verify email addresses and username configuration
  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  # User verification
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  # Advanced security features
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = var.user_pool_tags
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "default" {
  count        = local.create_user_pool ? 1 : 0
  domain       = local.user_pool_domain_name
  user_pool_id = aws_cognito_user_pool.default[0].id
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "default" {
  count        = local.create_user_pool ? 1 : 0
  name         = "${var.user_pool_name}-client"
  user_pool_id = aws_cognito_user_pool.default[0].id

  # OAuth settings
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["implicit", "code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = var.user_pool_callback_urls
  logout_urls                          = var.user_pool_logout_urls

  # Token configuration
  id_token_validity                             = var.user_pool_token_validity_hours
  access_token_validity                         = var.user_pool_token_validity_hours
  refresh_token_validity                        = var.user_pool_refresh_token_validity_days
  prevent_user_existence_errors                 = "ENABLED"
  enable_token_revocation                       = true
  enable_propagate_additional_user_context_data = false

  # Auth flows
  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  supported_identity_providers = ["COGNITO"]
}

# Cognito default admin user (optional)
resource "aws_cognito_user" "admin" {
  count = local.create_user_pool && var.user_pool_create_admin ? 1 : 0

  user_pool_id = aws_cognito_user_pool.default[0].id
  username     = var.user_pool_admin_email

  attributes = {
    email          = var.user_pool_admin_email
    email_verified = "true"
  }

  password = random_password.password[0].result
}
