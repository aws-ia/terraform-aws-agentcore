# CodeBuild projects for runtime builds
# All runtimes use CodeBuild to ensure correct ARM64 binaries

# CodeBuild project for CONTAINER runtimes (Docker build → ECR)
resource "aws_codebuild_project" "runtime_container" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if config.source_type == "CONTAINER" && config.container_source_path != null
  }

  name          = "${var.project_prefix}-${each.key}-container"
  service_role  = aws_iam_role.codebuild_container[each.key].arn
  build_timeout = 60

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/amazonlinux2-aarch64-standard:3.0"
    type                       = "ARM_CONTAINER"
    privileged_mode            = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.id
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.runtime[each.key].name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = each.value.container_image_tag
    }

    environment_variable {
      name  = "DOCKERFILE_NAME"
      value = each.value.container_dockerfile_name
    }
  }

  source {
    type      = "S3"
    location  = "${aws_s3_bucket.runtime[each.key].id}/source-input.zip"
    buildspec = <<-EOT
      version: 0.2
      phases:
        pre_build:
          commands:
            - echo Logging in to Amazon ECR...
            - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
        build:
          commands:
            - echo Build started on `date`
            - echo Building the Docker image...
            - docker build --platform linux/arm64 -t $IMAGE_REPO_NAME:$IMAGE_TAG -f $DOCKERFILE_NAME .
            - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
        post_build:
          commands:
            - echo Build completed on `date`
            - echo Pushing the Docker image...
            - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
            - echo Waiting for ECR eventual consistency...
            - |
              for i in {1..30}; do
                if aws ecr describe-images --repository-name $IMAGE_REPO_NAME --image-ids imageTag=$IMAGE_TAG --region $AWS_DEFAULT_REGION 2>/dev/null; then
                  echo "Image confirmed available in ECR after $i attempts"
                  exit 0
                fi
                echo "Attempt $i: Image not yet available, waiting 2 seconds..."
                sleep 2
              done
              echo "ERROR: Image not available after 30 attempts (60 seconds)"
              exit 1
    EOT
  }

  tags = local.merged_tags
}

# CodeBuild project for CODE runtimes (pip install → zip → S3)
resource "aws_codebuild_project" "runtime_code" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if config.source_type == "CODE" && config.code_source_path != null
  }

  name          = "${var.project_prefix}-${each.key}-code"
  service_role  = aws_iam_role.codebuild_code[each.key].arn
  build_timeout = 15

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/amazonlinux2-aarch64-standard:3.0"
    type                       = "ARM_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "S3_BUCKET"
      value = aws_s3_bucket.runtime[each.key].id
    }
  }

  source {
    type      = "S3"
    location  = "${aws_s3_bucket.runtime[each.key].id}/source-input.zip"
    buildspec = <<-EOT
      version: 0.2
      phases:
        build:
          commands:
            - echo Installing dependencies for ARM64...
            - |
              if [ -f requirements.txt ]; then
                pip3 install -r requirements.txt -t . --platform manylinux2014_aarch64 --only-binary=:all: --upgrade
                rm requirements.txt
              fi
        post_build:
          commands:
            - echo Packaging and uploading to S3...
            - zip -r /tmp/runtime.zip .
            - aws s3 cp /tmp/runtime.zip s3://$S3_BUCKET/source.zip
            - echo Waiting for S3 eventual consistency...
            - |
              for i in {1..30}; do
                if aws s3api head-object --bucket $S3_BUCKET --key source.zip 2>/dev/null; then
                  echo "Artifact confirmed available in S3 after $i attempts"
                  exit 0
                fi
                echo "Attempt $i: Artifact not yet available, waiting 2 seconds..."
                sleep 2
              done
              echo "ERROR: Artifact not available after 30 attempts (60 seconds)"
              exit 1
    EOT
  }

  tags = local.merged_tags
}

# Action: Start CODE build
action "aws_codebuild_start_build" "code" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if config.source_type == "CODE" && config.code_source_path != null
  }

  config {
    project_name = aws_codebuild_project.runtime_code[each.key].name
    timeout      = 900
  }
}

# Trigger CODE build on source change
resource "terraform_data" "build_trigger_code" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if config.source_type == "CODE" && config.code_source_path != null
  }

  input = data.archive_file.runtime_source[each.key].output_md5

  lifecycle {
    action_trigger {
      events  = [before_create, before_update]
      actions = [action.aws_codebuild_start_build.code[each.key]]
    }
  }

  depends_on = [
    aws_s3_object.runtime_source_input,
    aws_codebuild_project.runtime_code,
    time_sleep.codebuild_iam_propagation
  ]
}

# Action: Start CONTAINER build
action "aws_codebuild_start_build" "container" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if config.source_type == "CONTAINER" && config.container_source_path != null
  }

  config {
    project_name = aws_codebuild_project.runtime_container[each.key].name
    timeout      = 3600
  }
}

# Trigger CONTAINER build on source change
resource "terraform_data" "build_trigger_container" {
  for_each = {
    for name, config in var.runtimes :
    name => config
    if config.source_type == "CONTAINER" && config.container_source_path != null
  }

  input = data.archive_file.runtime_source[each.key].output_md5

  lifecycle {
    action_trigger {
      events  = [before_create, before_update]
      actions = [action.aws_codebuild_start_build.container[each.key]]
    }
  }

  depends_on = [
    aws_s3_object.runtime_source_input,
    aws_codebuild_project.runtime_container,
    time_sleep.codebuild_iam_propagation
  ]
}



