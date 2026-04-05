TERRAFORM ?= terraform
TF_DIR := terraform/envs/prod
IAC_DIR := terraform

.PHONY: fmt fmt-check init validate plan tfsec checkov

fmt:
	$(TERRAFORM) fmt -recursive $(IAC_DIR)

fmt-check:
	$(TERRAFORM) fmt -check -recursive $(IAC_DIR)

init:
	$(TERRAFORM) -chdir=$(TF_DIR) init

validate: init
	$(TERRAFORM) -chdir=$(TF_DIR) validate

plan: init
	$(TERRAFORM) -chdir=$(TF_DIR) plan

tfsec:
	tfsec $(IAC_DIR)

checkov:
	checkov -d $(IAC_DIR)
