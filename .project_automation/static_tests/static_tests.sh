#!/bin/bash

## NOTE: paths may differ when running in a managed task. To ensure behavior is consistent between
# managed and local tasks always use these variables for the project and project type path
PROJECT_PATH=${BASE_PATH}/project
PROJECT_TYPE_PATH=${BASE_PATH}/projecttype

echo "Starting Static Tests"

#********** Terraform Validate *************
cd ${PROJECT_PATH}
terraform init
terraform validate
if [ $? -eq 0 ]
then
    echo "Success - Terraform validate"
else
    echo "Failure - Terraform validate"
    exit 1
fi

#********** tflint ********************
echo 'Starting tflint'
tflint --init --config ${PROJECT_PATH}/.config/.tflint.hcl 2>&1
if [ $? -ne 0 ]; then
    echo "Failure - tflint init failed!"
    exit 1
fi
tflint --force --config ${PROJECT_PATH}/.config/.tflint.hcl
if [ $? -eq 0 ]
then
    echo "Success - tflint found no linting issues!"
else
    echo "Failure - tflint found linting issues!"
    exit 1
fi

#********** tfsec *********************
echo 'Skipping tfsec - does not support Terraform 1.14 Actions yet'
echo 'See: https://github.com/aquasecurity/tfsec/discussions/1994'
echo 'Success - tfsec skipped'

#********** Checkov Analysis *************
echo "Running Checkov Analysis"
checkov --config-file ${PROJECT_PATH}/.config/.checkov.yml
if [ $? -eq 0 ]
then
    echo "Success - Checkov found no issues!"
else
    echo "Failure - Checkov found issues!"
    exit 1
fi

#********** Markdown Lint **************
echo 'Starting markdown lint'
MYMDL=$(markdownlint --config ${PROJECT_PATH}/.config/.markdownlint.json .header.md examples/*/.header.md)
if [ -z "$MYMDL" ]
then
    echo "Success - markdown lint found no linting issues!"
else
    echo "Failure - markdown lint found linting issues!"
    echo "$MYMDL"
    exit 1
fi

#********** Terraform Docs *************
echo 'Starting terraform-docs'
terraform-docs --config ${PROJECT_PATH}/.config/.terraform-docs.yaml --lockfile=false --recursive --recursive-path=examples/ ./
if [ $? -eq 0 ]
then
    echo "Success - Terraform Docs generated!"
else
    echo "Failure - Terraform Docs generation failed!"
    exit 1
fi

#***************************************
echo "End of Static Tests"