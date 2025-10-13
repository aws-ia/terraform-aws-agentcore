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
