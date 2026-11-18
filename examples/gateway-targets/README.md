<!-- BEGIN_TF_DOCS -->
# Gateway Targets Example

This example shows the gateway target types beyond Lambda tools, together with JWT inbound authorization and the runtime attributes that go with them:

- a **CODE runtime** that serves HTTP, accepts JWT bearer tokens from an identity provider, forwards two custom headers and limits session lifetime
- `tools-gateway`, an **MCP gateway** with an `MCP_SERVER` target that carries a static tool schema (no discovery call to the server), a resource priority, header propagation, an MCP session timeout and response streaming
- `agents-gateway`, a gateway with **`protocol_type = "NONE"`** and two HTTP targets: an `AGENTCORE_RUNTIME` target that routes to the runtime above, and an `HTTP_PASSTHROUGH` target to an external A2A agent with session stickiness

**⚠️ ARM64 Requirement**: AgentCore requires ARM64 Python binaries. The module automatically handles this via CodeBuild - no local Docker needed.

## What Gets Created

- 1 Cognito user pool and app client (the OpenID Connect provider for the JWT authorizers)
- 1 AgentCore Runtime (`support_agent`) with its endpoint, S3 bucket, CodeBuild project and IAM role
- 2 gateways with their IAM roles; the `agents-gateway` role may invoke the runtime (`bedrock-agentcore:InvokeAgentRuntime`)
- 3 gateway targets
- `autogen/.env` - Environment variables with actual AWS resource IDs

## Target Types

| `type` | Gateway `protocol_type` | Configuration block | Outbound credentials |
|--------|-------------------------|---------------------|----------------------|
| `LAMBDA` | `MCP` | `lambda_config` | `GATEWAY_IAM_ROLE` |
| `MCP_SERVER` | `MCP` | `mcp_server_config` (optional `tool_schema`, `listing_mode`, `resource_priority`) | none, `API_KEY` or `OAUTH` |
| `AGENTCORE_RUNTIME` | `NONE` | `agentcore_runtime_config` (`runtime_name` or `runtime_arn`, `qualifier`, optional `schema`) | `GATEWAY_IAM_ROLE` (the default, without a SigV4 service), `CALLER_IAM_CREDENTIALS`, `OAUTH` or `JWT_PASSTHROUGH` |
| `HTTP_PASSTHROUGH` | `NONE` | `passthrough_config` (`endpoint`, `protocol_type` MCP/A2A/INFERENCE/CUSTOM, optional `schema`, static query parameters, stickiness) | `GATEWAY_IAM_ROLE` with `gateway_iam_role_config.service`, `API_KEY`, `OAUTH` or `JWT_PASSTHROUGH` |

HTTP targets are addressed by path: `https://<gateway url host>/<target name>/invocations` for a runtime target and `https://<gateway url host>/<target name>/<path>` for passthrough targets. Target names are prefixed with `project_prefix` (see the `gateway_target_names` output).

## Usage

```bash
cd examples/gateway-targets
terraform init
terraform apply
```

## Testing

Obtain an access token for the app client from Cognito (for example with a user created in the pool and `aws cognito-idp initiate-auth`), then call the runtime through the gateway:

```bash
GATEWAY_URL=$(terraform output -json gateway_urls | jq -r '."agents-gateway"')
TARGET=$(terraform output -json gateway_target_names | jq -r '."support-agent"')

curl -X POST "${GATEWAY_URL%/mcp}/${TARGET}/invocations" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "X-Correlation-Id: demo-1" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Hello"}'
```

The `tools-gateway` additionally requires the token's `token_use` claim to equal `access` (the custom claim rule), and keeps MCP sessions for 30 minutes.

## Notes

- `weather-mcp` points at a placeholder endpoint; because it declares a static `tool_schema`, the gateway does not contact the server when the target is created. Remove `tool_schema` to let the gateway discover and synchronize tools from a real server.
- `partner-agent` forwards the caller's JWT unchanged (`JWT_PASSTHROUGH`); use `OAUTH` with a credential provider when the partner expects its own tokens.
- To make the runtime reachable only through the gateway, add `allowed_workload_configuration` to the runtime's `custom_jwt_authorizer` with the gateway's workload identity name once the gateway exists.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_terraform-aws-agentcore"></a> [terraform-aws-agentcore](#module\_terraform-aws-agentcore) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cognito_user_pool.agents](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_user_pool_client.agents](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) | resource |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_client_id"></a> [client\_id](#output\_client\_id) | Client ID accepted by the runtime and the gateways |
| <a name="output_discovery_url"></a> [discovery\_url](#output\_discovery\_url) | OpenID Connect discovery URL of the example identity provider |
| <a name="output_gateway_target_ids"></a> [gateway\_target\_ids](#output\_gateway\_target\_ids) | Map of gateway target names to their IDs |
| <a name="output_gateway_target_names"></a> [gateway\_target\_names](#output\_gateway\_target\_names) | Map of gateway target names to their resource names (HTTP targets are reached at <gateway url>/<target name>/...) |
| <a name="output_gateway_urls"></a> [gateway\_urls](#output\_gateway\_urls) | Map of gateway names to their URLs |
| <a name="output_runtime_ids"></a> [runtime\_ids](#output\_runtime\_ids) | Map of runtime names to their IDs |
<!-- END_TF_DOCS -->