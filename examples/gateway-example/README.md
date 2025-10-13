<!-- BEGIN_TF_DOCS -->
# Bedrock AgentCore Gateway Example

This example demonstrates how to create an AWS Bedrock AgentCore Gateway that can connect to a Lambda function target.

## Overview

This example:
1. Creates a simple Lambda function that will serve as a gateway target
2. Sets up a Bedrock AgentCore Gateway with proper IAM permissions
3. Configures the gateway to connect to the Lambda function

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

### 4. Connect the Lambda function as a target (Console required)

After the gateway is created, you'll need to use the AWS Console or AWS CLI to create a gateway target, as the Terraform resource for gateway targets is not currently available:

1. Go to the AWS Bedrock console
2. Navigate to "Agents" section and select "Agent Core"
3. Select "Gateways" and click on your newly created gateway
4. In the "Targets" tab, click "Create target"
5. Configure the target to point to the Lambda function created by this example

### 5. Cleanup

```
terraform destroy
```

## Architecture

This example creates:

- AWS Lambda function that returns a simple JSON response
- IAM role and policy for the Lambda function
- Bedrock AgentCore Gateway with proper IAM permissions
- IAM role and policy for the Gateway to invoke the Lambda function

## Notes

- The gateway's protocol type is set to MCP (Model Context Protocol)

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

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bedrock_agent_gateway"></a> [bedrock\_agent\_gateway](#module\_bedrock\_agent\_gateway) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.lambda_basic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.example_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
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
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | ARN of the Lambda function created as a gateway target |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | Name of the Lambda function created as a gateway target |
<!-- END_TF_DOCS -->