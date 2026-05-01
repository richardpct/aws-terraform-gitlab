.DEFAULT_GOAL  := help
TERRAFORM_LOCK := .terraform.lock.hcl
ENV            := dev
SECRET_ENV     := ~/terraform/aws-terraform-gitlab/terraform_vars_$(ENV)_secrets

.PHONY: help
help: ## Show help
	@echo "Usage: make TARGET\n"
	@echo "Targets:"
	@awk -F ":.* ##" '/^[^#].*:.*##/{printf "%-13s%s\n", $$1, $$2}' \
	$(MAKEFILE_LIST) \
	| grep -v awk

$(TERRAFORM_LOCK):
	. $(SECRET_ENV) && \
	tofu init

.PHONY: init
init: $(TERRAFORM_LOCK) ## Init

.PHONY: apply
apply: init ## Create the infrastructure
	. $(SECRET_ENV) && \
	tofu apply

.PHONY: plan
plan: init ## Dry run
	. $(SECRET_ENV) && \
	tofu plan

.PHONY: destroy
destroy: ## Destroy the infrastructure
	. $(SECRET_ENV) && \
	tofu destroy

.PHONY: clean
clean: ## Clean
	rm -rfv .terraform*
