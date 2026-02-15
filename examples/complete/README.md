<!-- BEGIN_TF_DOCS -->
# Complete Example

This example demonstrates all AgentCore resources working together:

- **2 Runtimes**: CODE (Python) + CONTAINER (Docker with STRANDS)
- **Memory**: With 3 built-in strategies (semantic, summary, user preference)
- **Gateway**: MCP protocol gateway
- **Gateway Target**: Lambda function integration
- **Browser**: Custom browser (recording disabled)
- **Code Interpreter**: Secure Python execution

**⚠️ ARM64 Requirement**: Both CODE and CONTAINER runtimes require ARM64 architecture. The module automatically handles this via CodeBuild.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Auto-Generated Files

Terraform creates files in the `autogen/` directory:
- `autogen/.env` - Environment variables with actual AWS resource IDs
- `autogen/test_*.sh` - Test scripts for each runtime
- `autogen/lambda.zip` - Lambda deployment package

**Note:** The `autogen/` directory is gitignored and safe to delete.

## What Gets Created

- 2 AgentCore runtimes with endpoints (both update in-place with zero downtime)
- 1 Memory resource with 3 strategies
- 1 Gateway with MCP protocol
- 1 Gateway target pointing to Lambda
- 1 Custom browser (recording disabled)
- 1 Code interpreter in sandbox mode
- Lambda function for gateway target
- S3 buckets for CODE runtime
- ECR repository + CodeBuild (ARM64) for CONTAINER runtime
- IAM roles for all resources

## Testing

**Preferred: AWS Console** - Navigate to [Amazon Bedrock > AgentCore > Test](https://console.aws.amazon.com/bedrock-agentcore/playground) and use the Agent sandbox UI.

Or use the generated test scripts:

```bash
./autogen/test_python_agent.sh "Hello world"
./autogen/test_container_agent.sh "What can you do?"
```

Or invoke directly with AWS CLI:

```bash
aws bedrock-agent-runtime invoke-agent \
  --agent-runtime-id <runtime-id> \
  --input-text "Hello" \
  --region us-east-1
```

## Code Updates

Both runtimes support zero-downtime updates:

```bash
# Edit code
vim ../basic-code-runtime/src/agent.py
vim ../basic-container-runtime/src/app.py

# Apply - updates in-place
terraform apply
```

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_terraform-aws-agentcore"></a> [terraform-aws-agentcore](#module\_terraform-aws-agentcore) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.lambda_basic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.gateway_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [archive_file.lambda_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_browser_ids"></a> [browser\_ids](#output\_browser\_ids) | Map of browser names to their IDs |
| <a name="output_code_interpreter_ids"></a> [code\_interpreter\_ids](#output\_code\_interpreter\_ids) | Map of code interpreter names to their IDs |
| <a name="output_ecr_repository_urls"></a> [ecr\_repository\_urls](#output\_ecr\_repository\_urls) | Map of CONTAINER runtime names to their ECR repository URLs |
| <a name="output_gateway_ids"></a> [gateway\_ids](#output\_gateway\_ids) | Map of gateway names to their IDs |
| <a name="output_gateway_target_ids"></a> [gateway\_target\_ids](#output\_gateway\_target\_ids) | Map of gateway target names to their IDs |
| <a name="output_gateway_urls"></a> [gateway\_urls](#output\_gateway\_urls) | Map of gateway names to their URLs |
| <a name="output_memory_ids"></a> [memory\_ids](#output\_memory\_ids) | Map of memory names to their IDs |
| <a name="output_runtime_endpoints"></a> [runtime\_endpoints](#output\_runtime\_endpoints) | Map of runtime names to their endpoint ARNs |
| <a name="output_runtime_ids"></a> [runtime\_ids](#output\_runtime\_ids) | Map of runtime names to their IDs |
| <a name="output_s3_bucket_names"></a> [s3\_bucket\_names](#output\_s3\_bucket\_names) | Map of runtime names to their S3 bucket names |
<!-- END_TF_DOCS -->