terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 0.24.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0.0"
    }
  }
}

provider "aws" {
  region = local.region
}

provider "awscc" {
  region = local.region
}

locals {
  region = "us-east-1"
  name   = "bedrock-gateway-example"
}

resource "random_id" "suffix" {
  byte_length = 4
}
