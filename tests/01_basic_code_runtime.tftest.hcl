run "plan_code_runtime" {
  command = plan
  module {
    source = "./examples/basic-code-runtime"
  }
}

run "apply_code_runtime" {
  command = apply
  module {
    source = "./examples/basic-code-runtime"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.runtime_ids)) == 1
    error_message = "Should create exactly 1 runtime"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.endpoint_ids)) == 1
    error_message = "Should create exactly 1 endpoint"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.s3_bucket_names)) == 1
    error_message = "Should create exactly 1 S3 bucket for CODE runtime"
  }
}
