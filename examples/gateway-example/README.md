<!-- BEGIN_TF_DOCS -->
# Bedrock AgentCore Gateway and Gateway Target Example

This example demonstrates how to create an AWS Bedrock AgentCore Gateway and configure a Gateway Target that connects to a Lambda function.

## Overview

This example:

1. Creates a simple Lambda function that will serve as a gateway target
2. Sets up a Bedrock AgentCore Gateway with proper IAM permissions
3. Creates a Gateway Target that connects the gateway to the Lambda function with a defined schema

The AWS Bedrock AgentCore Gateway enables generative AI clients to send requests to your service implementations. This example focuses on setting up a gateway with Lambda function integration.

## Prerequisites

- AWS CLI installed and configured
- Terraform installed
- An AWS account with permissions to create Lambda functions and Bedrock resources

## Usage

### 1. Initialize the Terraform configuration

```
terraform init
```

### 2. Review the execution plan

```
terraform plan
```

### 3. Apply the configuration

```
terraform apply
```

### 4. Test the Gateway Target

After the gateway and gateway target are created, you can test them:

1. Go to the AWS Bedrock console
2. Navigate to "AgentCore" section and select "Gateways"
3. Select your newly created gateway
4. In the "Targets" tab, you should see your Lambda function target already configured
5. You can test the target using the AWS CLI:

```bash
aws bedrock-agent-runtime invoke-gateway \
  --gateway-id <gateway-id> \
  --target-name example-lambda-target \
  --body '{"query": "test query", "options": {"detailed": true}}' \
  --region <your-region>
```

### 5. Cleanup

```
terraform destroy
```

## Architecture

This example creates:

- AWS Lambda function that returns a simple JSON response
- IAM role and policy for the Lambda function
- Bedrock AgentCore Gateway with proper IAM permissions
- Gateway Target configured to use the Lambda function
- IAM role and policy for the Gateway to invoke the Lambda function

## Notes

- The gateway's protocol type is set to MCP (Model Context Protocol)
- For tool schemas stored in S3, the gateway IAM role will automatically include necessary S3 permissions

## Outputs

| Name | Description |
|------|-------------|
| lambda\_function\_arn | ARN of the Lambda function created as a gateway target |
| lambda\_function\_name | Name of the Lambda function created as a gateway target |
| agent\_gateway\_id | ID of the created Bedrock AgentCore Gateway |
| agent\_gateway\_arn | ARN of the created Bedrock AgentCore Gateway |
| agent\_gateway\_status | Status of the created Bedrock AgentCore Gateway |
| agent\_gateway\_url | URL of the created Bedrock AgentCore Gateway |
| gateway\_role\_arn | ARN of the IAM role created for the Bedrock AgentCore Gateway |
| gateway\_role\_name | Name of the IAM role created for the Bedrock AgentCore Gateway |
| gateway\_target\_id | ID of the created Bedrock AgentCore Gateway Target |
| gateway\_target\_name | Name of the created Bedrock AgentCore Gateway Target |
| gateway\_target\_gateway\_id | ID of the gateway that the target belongs to |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.24.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.0.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.0.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bedrock_agent_gateway"></a> [bedrock\_agent\_gateway](#module\_bedrock\_agent\_gateway) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [archive_file.lambda_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/resources/file) | resource |
| [aws_iam_role.lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.lambda_basic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.example_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [local_file.lambda_code](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_id.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_agent_gateway_arn"></a> [agent\_gateway\_arn](#output\_agent\_gateway\_arn) | ARN of the created Bedrock AgentCore Gateway |
| <a name="output_agent_gateway_id"></a> [agent\_gateway\_id](#output\_agent\_gateway\_id) | ID of the created Bedrock AgentCore Gateway |
| <a name="output_agent_gateway_status"></a> [agent\_gateway\_status](#output\_agent\_gateway\_status) | Status of the created Bedrock AgentCore Gateway |
| <a name="output_agent_gateway_url"></a> [agent\_gateway\_url](#output\_agent\_gateway\_url) | URL of the created Bedrock AgentCore Gateway |
| <a name="output_agent_gateway_workload_identity_details"></a> [agent\_gateway\_workload\_identity\_details](#output\_agent\_gateway\_workload\_identity\_details) | Workload identity details of the created Bedrock AgentCore Gateway |
| <a name="output_gateway_role_arn"></a> [gateway\_role\_arn](#output\_gateway\_role\_arn) | ARN of the IAM role created for the Bedrock AgentCore Gateway |
| <a name="output_gateway_role_name"></a> [gateway\_role\_name](#output\_gateway\_role\_name) | Name of the IAM role created for the Bedrock AgentCore Gateway |
| <a name="output_gateway_target_gateway_id"></a> [gateway\_target\_gateway\_id](#output\_gateway\_target\_gateway\_id) | ID of the gateway that the target belongs to |
| <a name="output_gateway_target_id"></a> [gateway\_target\_id](#output\_gateway\_target\_id) | ID of the created Bedrock AgentCore Gateway Target |
| <a name="output_gateway_target_name"></a> [gateway\_target\_name](#output\_gateway\_target\_name) | Name of the created Bedrock AgentCore Gateway Target |
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | ARN of the Lambda function created as a gateway target |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | Name of the Lambda function created as a gateway target |
<!-- END_TF_DOCS -->