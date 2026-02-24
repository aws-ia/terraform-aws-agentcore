run "plan_container_runtime" {
  command = plan
  module {
    source = "./examples/basic-container-runtime"
  }
}

run "apply_container_runtime" {
  command = apply
  module {
    source = "./examples/basic-container-runtime"
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
    error_message = "Should create exactly 1 S3 bucket for CONTAINER build artifacts"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.ecr_repository_urls)) == 1
    error_message = "Should create exactly 1 ECR repository for CONTAINER runtime"
  }

  assert {
    condition     = length(keys(module.terraform-aws-agentcore.codebuild_project_names)) == 1
    error_message = "Should create exactly 1 CodeBuild project for CONTAINER runtime"
  }
}
