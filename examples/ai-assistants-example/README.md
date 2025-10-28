<!-- BEGIN_TF_DOCS -->
# AI Assistants Example with Code Interpreter and Browser

This example demonstrates how to use the Terraform AWS AgentCore module to create a complete AI assistant setup with:

1. **Browser Custom** - A custom browser resource for the AI assistant to browse the web
2. **Code Interpreter Custom** - A code interpreter for the AI assistant to execute code

## Overview

This example creates the following resources:

- A Bedrock AgentCore Browser Custom with recording capabilities
- An S3 bucket for storing browser recordings
- A Bedrock AgentCore Code Interpreter Custom

The browser is configured to record sessions to an S3 bucket, allowing you to review browser interactions. The code interpreter runs in a sandbox environment for executing code securely.

## Prerequisites

1. An AWS account with appropriate permissions
2. Terraform >= 1.0.7
3. AWS provider >= 4.0.0
4. AWSCC provider >= 0.24.0
5. Appropriate IAM permissions to create the resources

## Usage

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Clean up resources when done
terraform destroy
```

## Notes

- The browser recording feature stores session recordings in an S3 bucket
- The code interpreter runs in a SANDBOX network mode for security

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.24.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ai_assistants"></a> [ai\_assistants](#module\_ai\_assistants) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.browser_recordings](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_browser_arn"></a> [browser\_arn](#output\_browser\_arn) | ARN of the created Bedrock AgentCore Browser Custom |
| <a name="output_browser_id"></a> [browser\_id](#output\_browser\_id) | ID of the created Bedrock AgentCore Browser Custom |
| <a name="output_browser_recordings_bucket"></a> [browser\_recordings\_bucket](#output\_browser\_recordings\_bucket) | S3 bucket for browser recordings |
| <a name="output_code_interpreter_arn"></a> [code\_interpreter\_arn](#output\_code\_interpreter\_arn) | ARN of the created Bedrock AgentCore Code Interpreter Custom |
| <a name="output_code_interpreter_id"></a> [code\_interpreter\_id](#output\_code\_interpreter\_id) | ID of the created Bedrock AgentCore Code Interpreter Custom |
| <a name="output_memory_id"></a> [memory\_id](#output\_memory\_id) | ID of the created Bedrock AgentCore Memory |
<!-- END_TF_DOCS -->