run "plan_complete" {
  command = plan
  module {
    source = "./examples/complete"
  }
}

run "apply_complete" {
  command = apply
  module {
    source = "./examples/complete"
  }

  # Test runtimes - should have python_agent and container_agent
  assert {
    condition     = length(keys(module.terraform-aws-agentcore.runtime_ids)) == 2
    error_message = "Should create exactly 2 runtimes (CODE + CONTAINER)"
  }

  assert {
    condition     = contains(keys(module.terraform-aws-agentcore.runtime_ids), "python_agent") && contains(keys(module.terraform-aws-agentcore.runtime_ids), "container_agent")
    error_message = "Should create python_agent and container_agent runtimes"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.endpoint_ids)) == 2
    error_message = "Should create exactly 2 endpoints"
  }

  # Test memory - should have semantic_memory
  assert {
    condition     = length(keys(module.terraform-aws-agentcore.memory_ids)) == 1
    error_message = "Should create exactly 1 memory"
  }

  assert {
    condition     = contains(keys(module.terraform-aws-agentcore.memory_ids), "semantic_memory")
    error_message = "Should create semantic_memory"
  }

  # Test gateway - should have mcp-gateway
  assert {
    condition     = length(keys(module.terraform-aws-agentcore.gateway_ids)) == 1
    error_message = "Should create exactly 1 gateway"
  }

  assert {
    condition     = contains(keys(module.terraform-aws-agentcore.gateway_ids), "mcp-gateway")
    error_message = "Should create mcp-gateway"
  }

  # Test gateway target - should have lambda-target
  assert {
    condition     = length(keys(module.terraform-aws-agentcore.gateway_target_ids)) == 1
    error_message = "Should create exactly 1 gateway target"
  }

  assert {
    condition     = contains(keys(module.terraform-aws-agentcore.gateway_target_ids), "lambda-target")
    error_message = "Should create lambda-target"
  }

  # Test browser - should have web_browser
  assert {
    condition     = length(keys(module.terraform-aws-agentcore.browser_ids)) == 1
    error_message = "Should create exactly 1 browser"
  }

  assert {
    condition     = contains(keys(module.terraform-aws-agentcore.browser_ids), "web_browser")
    error_message = "Should create web_browser"
  }

  # Test code interpreter - should have python_interpreter
  assert {
    condition     = length(keys(module.terraform-aws-agentcore.code_interpreter_ids)) == 1
    error_message = "Should create exactly 1 code interpreter"
  }

  assert {
    condition     = contains(keys(module.terraform-aws-agentcore.code_interpreter_ids), "python_interpreter")
    error_message = "Should create python_interpreter"
  }

  # Test S3 buckets (1 for CODE, 1 for CONTAINER builds)
  assert {
    condition     = length(keys(module.terraform-aws-agentcore.s3_bucket_names)) == 2
    error_message = "Should create exactly 2 S3 buckets"
  }

  # Test ECR repository (only for CONTAINER runtime)
  assert {
    condition     = length(keys(module.terraform-aws-agentcore.ecr_repository_urls)) == 1
    error_message = "Should create exactly 1 ECR repository for CONTAINER runtime"
  }

  assert {
    condition     = contains(keys(module.terraform-aws-agentcore.ecr_repository_urls), "container_agent")
    error_message = "Should create ECR repository for container_agent"
  }
}
