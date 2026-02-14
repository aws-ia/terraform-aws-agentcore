.PHONY: static-test functional-test

static-test:
	@echo "Running static tests..."
	terraform init
	terraform validate
	tflint --init --config .config/.tflint.hcl
	tflint --force --config .config/.tflint.hcl
	@echo "Skipping tfsec (doesn't support Terraform 1.14 Actions yet)"
	checkov --config-file .config/.checkov.yml
	markdownlint --config .config/.markdownlint.json .header.md examples/*/.header.md
	terraform-docs --config .config/.terraform-docs.yaml --lockfile=false --recursive --recursive-path=examples/ ./

functional-test:
	@echo "Running functional tests..."
	terraform test
