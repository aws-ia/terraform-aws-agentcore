# Terraform AgentCore Module Tests

Integration tests that validate the AgentCore module examples.

**⚠️ ARM64 Requirement**: All runtime tests use CodeBuild to automatically build ARM64 binaries/images. No local Docker required.

## Running Tests

```bash
# All tests
terraform test

# Specific test
terraform test -filter=tests/01_memory.tftest.hcl

# Plan only (no resources created)
terraform test -filter='run.plan_*'
```

## Test Files

Ordered from simplest to most complex:

- `00_unit_mocked.tftest.hcl` - Provider-mocked plan + apply of every example; no AWS credentials or resources needed (about a minute)
- `00_unit_resources.tftest.hcl` - Root-module unit tests with mocked providers: asserts on rendered resources (placeholder resolution, Cedar vs Dogwood definitions, IAM statements, gateway and target blocks, registry descriptors) (seconds)
- `00_unit_validations.tftest.hcl` - 48 negative tests, one invalid input each, expecting the matching variable validation to fail (seconds)
- `01_basic_code_runtime.tftest.hcl` - CODE runtime with ARM64 CodeBuild (~3-5min)
- `02_basic_container_runtime.tftest.hcl` - CONTAINER runtime with ARM64 CodeBuild (~5-10min)
- `03_complete.tftest.hcl` - All resources: 2 runtimes, memory, gateway, gateway target, browser, code interpreter (~10-15min)
- `04_agent_registry.tftest.hcl` - AWS Agent Registry registry, publisher IAM policy and role, MCP server record (~1-2min)
- `05_gateway_policy.tftest.hcl` - Gateway with a policy engine (ENFORCE), 2 Lambda targets, 2 Cedar policies and 1 Dogwood temporal policy (~3-5min)
- `06_configuration_bundles.tftest.hcl` - CODE runtime plus 2 configuration bundles keyed by the runtime ARN (~3-5min)
- `07_workload_identity.tftest.hcl` - CODE runtime (identity exposed as output) plus 1 managed workload identity (~3-5min)
- `08_gateway_targets.tftest.hcl` - Cognito-backed JWT runtime, MCP gateway with a static-schema MCP server target, protocol-less gateway with runtime and passthrough targets (~5-8min)

## Mocked Unit Tests

The three `00_unit_*` files run against `mock_provider` blocks for `aws`, `awscc` and `time`. Mock defaults only set the attributes providers validate on the client side (ARN and ID formats), so the runs exercise variable validation, placeholder resolution, IAM documents and the full resource graph without touching an AWS account:

- `00_unit_mocked` applies every example (end to end through the module).
- `00_unit_resources` feeds the root module variables directly and asserts on resource attributes, for example that `{{target:orders}}` resolves to `unit-orders` in a Cedar statement, that a Dogwood statement lands in `definition.policy`, or that the gateway role gets `AllowAgentRuntimeInvocation` for a runtime target.
- `00_unit_validations` proves each validation rule rejects bad input with `expect_failures`.

```bash
terraform init
terraform test -filter=tests/00_unit_mocked.tftest.hcl
terraform test -filter=tests/00_unit_resources.tftest.hcl
terraform test -filter=tests/00_unit_validations.tftest.hcl
```

Mocked state fills computed attributes with generated values, so these tests assert on configured values and on outputs, never on "attribute is null".

**Note:** All runtime tests use CodeBuild to build ARM64 packages/images automatically. No local Docker required.

## Future Enhancements

See [TODO.md](../TODO.md) for planned improvements including state-backed testing and CI/CD integration.
