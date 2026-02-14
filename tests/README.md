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

- `01_basic_code_runtime.tftest.hcl` - CODE runtime with ARM64 CodeBuild (~3-5min)
- `02_basic_container_runtime.tftest.hcl` - CONTAINER runtime with ARM64 CodeBuild (~5-10min)
- `03_complete.tftest.hcl` - All resources: 2 runtimes, memory, gateway, gateway target, browser, code interpreter (~10-15min)

**Note:** All runtime tests use CodeBuild to build ARM64 packages/images automatically. No local Docker required.

## Future Enhancements

See [TODO.md](../TODO.md) for planned improvements including state-backed testing and CI/CD integration.
