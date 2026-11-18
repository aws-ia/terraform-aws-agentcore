<!-- BEGIN_TF_DOCS -->
# Configuration Bundles Example

This example deploys a CODE runtime together with two **configuration bundles**: versioned, immutable snapshots of the agent's dynamic configuration (system prompt, model ID, temperature) that are selected per request, without redeploying code.

**⚠️ ARM64 Requirement**: AgentCore requires ARM64 Python binaries. The module automatically handles this via CodeBuild - no local Docker needed.

## What Gets Created

- 1 AgentCore Runtime (`support_agent`, Python 3.11) with its endpoint, S3 bucket, CodeBuild project and IAM role
- 2 configuration bundles (`support_agent_control`, `support_agent_treatment`), each with one component keyed by the runtime ARN
- The runtime role may read configuration bundles (`bedrock-agentcore:GetConfigurationBundle`, `GetConfigurationBundleVersion`)
- `autogen/.env` - Environment variables with actual AWS resource IDs (includes `CONFIGURATION_BUNDLES`)
- `autogen/test_support_agent.sh` - Test script for invoking the runtime

## How a Request Selects a Bundle

Nothing is attached to the runtime at deploy time. The caller (or an AgentCore Gateway rule / A/B test) names the bundle version in the request's W3C baggage, and the agent reads it with `BedrockAgentCoreContext.get_config_bundle()` (`bedrock-agentcore` SDK 1.8 or later, see `src/agent.py`):

```bash
# The module output already formats the baggage value for each bundle
BAGGAGE=$(terraform output -json configuration_bundle_baggage | jq -r '."support_agent_treatment"')
RUNTIME_ARN=$(terraform output -json runtime_arns | jq -r '."support_agent"')

aws bedrock-agentcore invoke-agent-runtime \
  --agent-runtime-arn "$RUNTIME_ARN" \
  --runtime-session-id "$(uuidgen)" \
  --baggage "$BAGGAGE" \
  --payload '{"prompt": "Where is my order?"}' \
  --region us-east-1 \
  response.json && cat response.json
```

The baggage carries two keys: `aws.agentcore.configbundle_arn` (the bundle ARN) and `aws.agentcore.configbundle_version` (a version ID). Requests without baggage get the defaults baked into the code.

## Versions, Branches and A/B Tests

- Every change to a bundle's `components` creates a new immutable version; `configuration_bundle_version_ids` always points at the latest one, and older version IDs keep working for rollbacks
- `branch_name` (default `mainline`) and `commit_message` record lineage, like a git history
- Component keys are usually ARNs. `{{runtime:<name>}}` and `{{gateway:<name>}}` placeholders resolve to resources created in the same module call
- An AgentCore A/B test (`create-ab-test` with `variantConfiguration.configurationBundle`) or a gateway rule injects the bundle reference for you, so one runtime serves both variants

## Usage

```bash
cd examples/configuration-bundles
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
| <a name="output_configuration_bundle_arns"></a> [configuration\_bundle\_arns](#output\_configuration\_bundle\_arns) | Map of configuration bundle names to their ARNs |
| <a name="output_configuration_bundle_baggage"></a> [configuration\_bundle\_baggage](#output\_configuration\_bundle\_baggage) | Per-bundle W3C baggage value that selects the bundle's current version for a request |
| <a name="output_configuration_bundle_version_ids"></a> [configuration\_bundle\_version\_ids](#output\_configuration\_bundle\_version\_ids) | Map of configuration bundle names to their current version IDs |
| <a name="output_runtime_arns"></a> [runtime\_arns](#output\_runtime\_arns) | Map of runtime names to their ARNs (the bundle component key) |
| <a name="output_runtime_ids"></a> [runtime\_ids](#output\_runtime\_ids) | Map of runtime names to their IDs |
<!-- END_TF_DOCS -->