<!-- BEGIN_TF_DOCS -->
# Gateway Policy Example

This example puts an AgentCore Gateway under **Policy in AgentCore**: a policy engine attached to the gateway in `ENFORCE` mode, with Cedar and Dogwood (temporal) policies that decide which tool calls go through.

## What This Example Does

- Creates a Lambda function that implements two tools: `get_order` and `refund_order`
- Creates a gateway (`orders-gateway`, IAM authorization) with one gateway target per tool
- Creates a policy engine (`orders_policy_engine`) and attaches it to the gateway in `ENFORCE` mode
- Creates three policies on the engine:
  - `AllowOrderLookup` (Cedar, `ACTIVE`): anyone the gateway authenticates may call `get_order`
  - `FlagLargeRefunds` (Cedar, `LOG_ONLY`): refunds above 500 are evaluated and logged, not yet denied
  - `RefundOnlyAfterLookup` (Dogwood, `ACTIVE`): a refund is permitted only if a successful `get_order` happened earlier in the same policy session
- Grants the gateway role the permissions the policy engine needs (`bedrock-agentcore:GetPolicyEngine`, `AuthorizeAction`, `PartiallyAuthorizeActions`, and `GetWorkloadAccessToken` for temporal policies)

## How Policies Reference Gateway Resources

Cedar actions are named after the gateway target and the tool: `<target name>___<tool name>`. Gateway target names are prefixed with `project_prefix`, and the gateway ARN only exists after the gateway is created, so the module resolves placeholders in policy statements before sending them to AWS:

| Placeholder | Resolves to |
|-------------|-------------|
| `{{gateway:orders-gateway}}` | the gateway ARN |
| `{{target:orders-lookup}}` | the gateway target name (`policy-example-orders-lookup`) |
| `{{runtime:<name>}}` | a runtime ARN (not used here) |

Policies are created after the gateway and its targets, because the service validates every statement against the tools the gateway exposes (`validation_mode = "FAIL_ON_ANY_FINDINGS"` by default).

## Usage

```bash
cd examples/gateway-policy
terraform init
terraform apply
```

## Testing

Call the gateway with an MCP client that signs requests with SigV4. Because the engine contains a temporal policy, **every request must carry a policy session ID** in the `x-amzn-bedrock-agentcore-policy-session-id` header (any string, a UUID is recommended, the same value for the whole conversation). Without it the gateway rejects the request.

Expected decisions inside one session:

| Sequence | Decision |
|----------|----------|
| `refund_order` with no prior lookup | DENY (no permit matches) |
| `get_order`, then `refund_order` for 100 | ALLOW |
| `get_order`, then `refund_order` for 900 | ALLOW, with `FlagLargeRefunds` logged as a would-be deny |

Promote `FlagLargeRefunds` by changing its `enforcement_mode` to `ACTIVE` and running `terraform apply` again. To observe before enforcing at the gateway level instead, set `policy_engine_configuration.mode = "LOG_ONLY"`.

## Auto-Generated Files

Terraform creates files in the `autogen/` directory:
- `autogen/.env` - Environment variables with actual AWS resource IDs (includes `POLICY_ENGINES`)
- `autogen/lambda.zip` - Lambda deployment package

**Note:** The `autogen/` directory is gitignored and safe to delete.

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
| [aws_lambda_function.orders](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [archive_file.lambda_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gateway_ids"></a> [gateway\_ids](#output\_gateway\_ids) | Map of gateway names to their IDs |
| <a name="output_gateway_target_names"></a> [gateway\_target\_names](#output\_gateway\_target\_names) | Map of gateway target names to their resource names (tool names are <target name>\_\_\_<tool>) |
| <a name="output_gateway_urls"></a> [gateway\_urls](#output\_gateway\_urls) | Map of gateway names to their URLs |
| <a name="output_policy_engine_arns"></a> [policy\_engine\_arns](#output\_policy\_engine\_arns) | Map of policy engine names to their ARNs |
| <a name="output_policy_engine_ids"></a> [policy\_engine\_ids](#output\_policy\_engine\_ids) | Map of policy engine names to their IDs |
| <a name="output_policy_ids"></a> [policy\_ids](#output\_policy\_ids) | Map of '<policy engine name>/<policy name>' to policy IDs |
<!-- END_TF_DOCS -->