<!-- BEGIN_TF_DOCS -->
# AWS Bedrock Agent Core Code-Based Runtime Example

This example demonstrates how to create an AWS Bedrock Agent Core runtime using a code-based artifact instead of a container-based approach. The code-based runtime uses Python code stored in an S3 bucket.

## Overview

This example:

1. Creates an S3 bucket for storing the runtime code
2. Generates a simple Python runtime handler with a sample implementation
3. Creates a zip file with the code and dependencies
4. Uploads the zip file to the S3 bucket
5. Provisions a Bedrock Agent Core runtime using the code-based artifact
6. Creates a runtime endpoint for invoking the runtime

## Pre-requisites

* AWS CLI configured with appropriate permissions
* Terraform >= 1.0.7
* S3 bucket permissions to create and manage buckets
* Bedrock Agent Core permissions to create and manage runtimes

## Usage

To run this example, execute the following commands:

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Clean up when done
terraform destroy
```

## Generated Files

This example automatically generates the following files during execution:

- `example_runtime.py`: A simple Python handler for the runtime
- `requirements.txt`: Dependencies for the Python runtime
- `agent_runtime_code.zip`: Zipped code package uploaded to S3

## Testing the Runtime

After applying the Terraform configuration:

1. The agent runtime will be provisioned with the code-based artifact
2. A runtime endpoint will be created for invoking the runtime
3. You can use the AWS Bedrock API to test the runtime endpoint

Example AWS CLI command to invoke the runtime (after deployment):

```bash
aws bedrock-agent-runtime invoke-agent \
  --agent-id <agent-id> \
  --agent-alias-id <agent-alias-id> \
  --session-id <session-id> \
  --input-text "Hello, agent!" \
  --region <region>
```

## Variables

No input variables are required for this example. It uses default values and random IDs to create unique resource names.

## Outputs

| Name | Description |
|------|-------------|
| `agent_runtime_id` | ID of the created Bedrock Agent Runtime |
| `agent_runtime_arn` | ARN of the created Bedrock Agent Runtime |
| `agent_runtime_status` | Status of the created Bedrock Agent Runtime |
| `agent_runtime_endpoint_id` | ID of the created Bedrock Agent Runtime Endpoint |
| `agent_runtime_endpoint_arn` | ARN of the created Bedrock Agent Runtime Endpoint |
| `agent_runtime_endpoint_status` | Status of the created Bedrock Agent Runtime Endpoint |
| `s3_bucket_name` | Name of the S3 bucket containing the agent runtime code |
| `s3_object_key` | S3 key of the agent runtime code object |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.60.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bedrock_agent_runtime"></a> [bedrock\_agent\_runtime](#module\_bedrock\_agent\_runtime) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.agent_runtime_code](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.agent_runtime_code_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.agent_runtime_code_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_object.agent_runtime_code_object](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [null_resource.create_code_zip](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_id.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_agent_runtime_arn"></a> [agent\_runtime\_arn](#output\_agent\_runtime\_arn) | ARN of the created Bedrock Agent Runtime |
| <a name="output_agent_runtime_endpoint_arn"></a> [agent\_runtime\_endpoint\_arn](#output\_agent\_runtime\_endpoint\_arn) | ARN of the created Bedrock Agent Runtime Endpoint |
| <a name="output_agent_runtime_endpoint_id"></a> [agent\_runtime\_endpoint\_id](#output\_agent\_runtime\_endpoint\_id) | ID of the created Bedrock Agent Runtime Endpoint |
| <a name="output_agent_runtime_endpoint_status"></a> [agent\_runtime\_endpoint\_status](#output\_agent\_runtime\_endpoint\_status) | Status of the created Bedrock Agent Runtime Endpoint |
| <a name="output_agent_runtime_id"></a> [agent\_runtime\_id](#output\_agent\_runtime\_id) | ID of the created Bedrock Agent Runtime |
| <a name="output_agent_runtime_status"></a> [agent\_runtime\_status](#output\_agent\_runtime\_status) | Status of the created Bedrock Agent Runtime |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | Name of the S3 bucket containing the agent runtime code |
| <a name="output_s3_object_key"></a> [s3\_object\_key](#output\_s3\_object\_key) | S3 key of the agent runtime code object |
<!-- END_TF_DOCS -->