<!-- BEGIN_TF_DOCS -->
# AgentCore Module

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
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | >= 0.24.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.runtime_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.runtime_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [awscc_bedrockagentcore_runtime.agent_runtime](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_runtime) | resource |
| [awscc_bedrockagentcore_runtime_endpoint.agent_runtime_endpoint](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_runtime_endpoint) | resource |
| [random_string.solution_prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_runtime"></a> [create\_runtime](#input\_create\_runtime) | Whether or not to create an agent core runtime. | `bool` | `false` | no |
| <a name="input_create_runtime_endpoint"></a> [create\_runtime\_endpoint](#input\_create\_runtime\_endpoint) | Whether or not to create an agent core runtime endpoint. | `bool` | `false` | no |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | The ARN of the IAM permission boundary for the role. | `string` | `null` | no |
| <a name="input_runtime_authorizer_configuration"></a> [runtime\_authorizer\_configuration](#input\_runtime\_authorizer\_configuration) | Authorizer configuration for the agent core runtime. | <pre>object({<br>    custom_jwt_authorizer = object({<br>      allowed_audience = optional(list(string))<br>      allowed_clients  = optional(list(string))<br>      discovery_url    = string<br>    })<br>  })</pre> | `null` | no |
| <a name="input_runtime_container_uri"></a> [runtime\_container\_uri](#input\_runtime\_container\_uri) | The ECR URI of the container for the agent core runtime. | `string` | `null` | no |
| <a name="input_runtime_description"></a> [runtime\_description](#input\_runtime\_description) | Description of the agent runtime. | `string` | `null` | no |
| <a name="input_runtime_endpoint_agent_runtime_id"></a> [runtime\_endpoint\_agent\_runtime\_id](#input\_runtime\_endpoint\_agent\_runtime\_id) | The ID of the agent core runtime associated with the endpoint. If not provided, it will use the ID of the agent runtime created by this module. | `string` | `null` | no |
| <a name="input_runtime_endpoint_description"></a> [runtime\_endpoint\_description](#input\_runtime\_endpoint\_description) | Description of the agent core runtime endpoint. | `string` | `null` | no |
| <a name="input_runtime_endpoint_name"></a> [runtime\_endpoint\_name](#input\_runtime\_endpoint\_name) | The name of the agent core runtime endpoint. | `string` | `"TerraformBedrockAgentCoreRuntimeEndpoint"` | no |
| <a name="input_runtime_endpoint_tags"></a> [runtime\_endpoint\_tags](#input\_runtime\_endpoint\_tags) | A map of tag keys and values for the agent core runtime endpoint. | `map(string)` | `null` | no |
| <a name="input_runtime_environment_variables"></a> [runtime\_environment\_variables](#input\_runtime\_environment\_variables) | Environment variables for the agent core runtime. | `map(string)` | `null` | no |
| <a name="input_runtime_name"></a> [runtime\_name](#input\_runtime\_name) | The name of the agent core runtime. | `string` | `"TerraformBedrockAgentCoreRuntime"` | no |
| <a name="input_runtime_network_mode"></a> [runtime\_network\_mode](#input\_runtime\_network\_mode) | Network mode configuration type for the agent core runtime. Valid values: PUBLIC, VPC. | `string` | `"PUBLIC"` | no |
| <a name="input_runtime_protocol_configuration"></a> [runtime\_protocol\_configuration](#input\_runtime\_protocol\_configuration) | Protocol configuration for the agent core runtime. | `string` | `null` | no |
| <a name="input_runtime_role_arn"></a> [runtime\_role\_arn](#input\_runtime\_role\_arn) | Optional external IAM role ARN for the Bedrock agent core runtime. If empty, the module will create one internally. | `string` | `null` | no |
| <a name="input_runtime_tags"></a> [runtime\_tags](#input\_runtime\_tags) | A map of tag keys and values for the agent core runtime. | `map(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_agent_runtime_arn"></a> [agent\_runtime\_arn](#output\_agent\_runtime\_arn) | ARN of the created Bedrock AgentCore Runtime |
| <a name="output_agent_runtime_endpoint_arn"></a> [agent\_runtime\_endpoint\_arn](#output\_agent\_runtime\_endpoint\_arn) | ARN of the created Bedrock AgentCore Runtime Endpoint |
| <a name="output_agent_runtime_endpoint_id"></a> [agent\_runtime\_endpoint\_id](#output\_agent\_runtime\_endpoint\_id) | ID of the created Bedrock AgentCore Runtime Endpoint |
| <a name="output_agent_runtime_endpoint_live_version"></a> [agent\_runtime\_endpoint\_live\_version](#output\_agent\_runtime\_endpoint\_live\_version) | Live version of the created Bedrock AgentCore Runtime Endpoint |
| <a name="output_agent_runtime_endpoint_status"></a> [agent\_runtime\_endpoint\_status](#output\_agent\_runtime\_endpoint\_status) | Status of the created Bedrock AgentCore Runtime Endpoint |
| <a name="output_agent_runtime_endpoint_target_version"></a> [agent\_runtime\_endpoint\_target\_version](#output\_agent\_runtime\_endpoint\_target\_version) | Target version of the created Bedrock AgentCore Runtime Endpoint |
| <a name="output_agent_runtime_id"></a> [agent\_runtime\_id](#output\_agent\_runtime\_id) | ID of the created Bedrock AgentCore Runtime |
| <a name="output_agent_runtime_status"></a> [agent\_runtime\_status](#output\_agent\_runtime\_status) | Status of the created Bedrock AgentCore Runtime |
| <a name="output_agent_runtime_version"></a> [agent\_runtime\_version](#output\_agent\_runtime\_version) | Version of the created Bedrock AgentCore Runtime |
| <a name="output_agent_runtime_workload_identity_details"></a> [agent\_runtime\_workload\_identity\_details](#output\_agent\_runtime\_workload\_identity\_details) | Workload identity details of the created Bedrock AgentCore Runtime |
<!-- END_TF_DOCS -->