#!/bin/bash

## NOTE: paths may differ when running in a managed task. To ensure behavior is consistent between
# managed and local tasks always use these variables for the project and project type path
PROJECT_PATH=${BASE_PATH}/project
PROJECT_TYPE_PATH=${BASE_PATH}/projecttype

echo "Starting Functional Tests"
cd ${PROJECT_PATH}

#********** Terraform Test **********

# Check if any test files exist
TEST_FILES=$(find ./tests -name "*.tftest.hcl" 2>/dev/null | wc -l)
if [ "$TEST_FILES" -gt 0 ]; then
    echo "Found $TEST_FILES test file(s), running tests"
    # Run Terraform test
    terraform init
    terraform test
else
    echo "No .tftest.hcl files found in ./tests directory. You must include at least one test file."
    (exit 1)
fi 

if [ $? -eq 0 ]; then
    echo "Terraform Test Successfull"
else
    echo "Terraform Test Failed"
    exit 1
fi

echo "End of Functional Tests"