# =============================================================================
# DATA SOURCES
# =============================================================================
# This file contains non-IAM data sources used across the module.
# IAM-related data sources (aws_iam_policy_document, aws_iam_policy) are in iam.tf

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# Random string for resource naming
resource "random_string" "solution_prefix" {
  length  = 5
  special = false
  upper   = false
}
