<!-- BEGIN_TF_DOCS -->
# Agent Registry Example

This example creates an **AWS Agent Registry** registry, the IAM a publishing pipeline needs to write records into it, and one Terraform-managed MCP server record.

AWS Agent Registry now lives in the `agent-registry` namespace (the public-preview `bedrock-agentcore` registry APIs shut down on October 30, 2026). The module uses the `agent-registry` resources and IAM actions only.

## What Gets Created

- 1 registry (`team-agent-registry`, IAM authorization, manual approval of submitted records)
- 1 IAM policy (`registry-example-team-agent-registry-registry-publisher`) that allows creating, updating, tagging and submitting records in this registry
- 1 IAM role with the same name that CodeBuild can assume, with the policy attached
- 1 registry record of type `MCP` describing a weather MCP server (created in `DRAFT`)
- `autogen/.env` - Environment variables with actual AWS resource IDs (includes `REGISTRIES`)

## Usage

```bash
cd examples/agent-registry
terraform init
terraform apply
```

## Publishing Records From a Pipeline

Most records are written at run time by the pipeline that builds and deploys an agent, not by Terraform. Give that pipeline the publisher policy (or let it assume the publisher role) and call the registry API:

```bash
REGISTRY_ID=$(terraform output -json registry_ids | jq -r '."team-agent-registry"')

# 1. Create (or update) the record - here an A2A agent card for an agent
aws agent-registry-control create-registry-record \
  --registry-id "$REGISTRY_ID" \
  --name "support-agent" \
  --display-name "Support agent" \
  --record-type AGENT \
  --record-version "1.2.0" \
  --descriptors '{"a2aAgentCard": {"data": "{\"name\": \"Support agent\", \"description\": \"Answers order questions\", \"version\": \"1.2.0\", \"protocolVersion\": \"0.3.0\", \"url\": \"https://api.example.com/a2a\", \"capabilities\": {}, \"defaultInputModes\": [\"text/plain\"], \"defaultOutputModes\": [\"text/plain\"], \"skills\": [{\"id\": \"orders\", \"name\": \"Orders\", \"description\": \"Order lookup\", \"tags\": [\"support\"]}]}", "dataSchemaVersion": "0.3"}}'

# 2. Submit it for approval (auto-approved when the registry has auto_approve_records = true)
aws agent-registry-control submit-registry-record-for-approval \
  --registry-id "$REGISTRY_ID" \
  --record-id <record-id from step 1>
```

Supported record types and descriptors: `MCP` (`mcpServer`), `AGENT` (`a2aAgentCard`, `mcpServer` or `custom`), `SKILL` (`agentSkillsDefinition`), `CUSTOM` (`custom`). A record becomes discoverable (searchable and visible on the registry's MCP endpoint) once it is approved.

## Options

- `authorizer_type = "CUSTOM_JWT"` with `authorizer_configuration.custom_jwt_authorizer` lets consumers discover records with tokens from your identity provider instead of IAM credentials
- `auto_approve_records = true` approves every submitted record immediately (pair it with tight control over who may submit)
- `publisher.trusted_principal_arns` trusts IAM principals (for example a CodePipeline or GitHub Actions role) instead of, or in addition to, services
- `publisher.allow_approval = true` also grants `agent-registry:UpdateRegistryRecordStatus` so the publisher can approve, reject or deprecate records
- `kms_key_arn` encrypts the registry with a customer managed key

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
| <a name="output_registry_arns"></a> [registry\_arns](#output\_registry\_arns) | Map of registry names to their ARNs |
| <a name="output_registry_ids"></a> [registry\_ids](#output\_registry\_ids) | Map of registry names to their IDs |
| <a name="output_registry_publisher_policy_arns"></a> [registry\_publisher\_policy\_arns](#output\_registry\_publisher\_policy\_arns) | Map of registry names to the publisher IAM policy ARN (attach it to a pipeline role) |
| <a name="output_registry_publisher_role_arns"></a> [registry\_publisher\_role\_arns](#output\_registry\_publisher\_role\_arns) | Map of registry names to the publisher IAM role ARN |
| <a name="output_registry_record_ids"></a> [registry\_record\_ids](#output\_registry\_record\_ids) | Map of '<registry name>/<record name>' to registry record IDs |
<!-- END_TF_DOCS -->