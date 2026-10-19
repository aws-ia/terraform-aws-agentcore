<!-- BEGIN_TF_DOCS -->
# Workload Identity Example

This example shows the two kinds of **AgentCore Identity** workload identities the module works with:

- the identity AgentCore creates for every runtime (and gateway), exposed through the `runtime_workload_identity_arns` and `gateway_workload_identity_arns` outputs
- explicitly managed identities (`workload_identities`), for agents that run outside AgentCore Runtime or that need OAuth2 return URLs registered for 3-legged OAuth flows

**⚠️ ARM64 Requirement**: AgentCore requires ARM64 Python binaries. The module automatically handles this via CodeBuild - no local Docker needed.

## What Gets Created

- 1 AgentCore Runtime (`my_agent`, reusing the code of the basic-code-runtime example) with its endpoint, S3 bucket, CodeBuild project and IAM role
- 1 workload identity (`external-support-agent`) with an allowed OAuth2 return URL
- `autogen/.env` - Environment variables with actual AWS resource IDs (includes `WORKLOAD_IDENTITIES`)
- `autogen/test_my_agent.sh` - Test script for invoking the runtime

## Runtime Identity and Tokens

The runtime role created by the module may obtain workload access tokens for the runtime's own identity (`bedrock-agentcore:GetWorkloadAccessToken`, `GetWorkloadAccessTokenForJWT`, `GetWorkloadAccessTokenForUserId`, scoped to `workload-identity-directory/default/workload-identity/my_agent-*`). Agent code gets a token with the AgentCore Identity SDK, then exchanges it for third-party credentials through a credential provider:

```python
from bedrock_agentcore.identity.auth import requires_access_token

@requires_access_token(provider_name="my-oauth2-provider", scopes=["read"], auth_flow="USER_FEDERATION")
async def call_external_api(*, access_token: str):
    ...
```

All identities of the account live in one directory:

```bash
aws bedrock-agentcore-control list-workload-identities
```

## Usage

```bash
cd examples/workload-identity
terraform init
terraform apply
```

## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_terraform-aws-agentcore"></a> [terraform-aws-agentcore](#module\_terraform-aws-agentcore) | ../.. | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_runtime_ids"></a> [runtime\_ids](#output\_runtime\_ids) | Map of runtime names to their IDs |
| <a name="output_runtime_role_arns"></a> [runtime\_role\_arns](#output\_runtime\_role\_arns) | Map of runtime names to their IAM role ARNs |
| <a name="output_runtime_workload_identity_arns"></a> [runtime\_workload\_identity\_arns](#output\_runtime\_workload\_identity\_arns) | Map of runtime names to the ARN of the workload identity AgentCore created for the runtime |
| <a name="output_workload_identity_arns"></a> [workload\_identity\_arns](#output\_workload\_identity\_arns) | Map of workload identity names to their ARNs |
<!-- END_TF_DOCS -->