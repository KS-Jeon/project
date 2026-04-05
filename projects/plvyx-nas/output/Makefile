TERRAFORM ?= terraform
TF_DIR := terraform

.PHONY: fmt fmt-check init validate plan tfsec checkov

fmt:
	$(TERRAFORM) -chdir=$(TF_DIR) fmt -recursive

fmt-check:
	$(TERRAFORM) -chdir=$(TF_DIR) fmt -check -recursive

init:
	$(TERRAFORM) -chdir=$(TF_DIR) init

validate: init
	$(TERRAFORM) -chdir=$(TF_DIR) validate

plan: init
	$(TERRAFORM) -chdir=$(TF_DIR) plan

tfsec:
	tfsec $(TF_DIR)

checkov:
	checkov -d $(TF_DIR)
