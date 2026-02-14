###############################################################################
# Makefile — Common Terragrunt/Terraform operations for Nutanix deployment
###############################################################################

# Default deployment target
CLUSTER ?= cluster-01
DEPLOY_DIR := Deployments/$(CLUSTER)
VM_DIR := $(DEPLOY_DIR)/virtual_machines

.PHONY: help init plan apply destroy import fmt validate plan-all apply-all

help: ## Show this help
	@echo ""
	@echo "Nutanix Terraform/Terragrunt Deployment"
	@echo "========================================="
	@echo ""
	@echo "Usage: make <target> [CLUSTER=cluster-01]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ---------------------------------------------------------------------------
# Single-module targets (virtual_machines)
# ---------------------------------------------------------------------------

init: ## Initialize Terraform for VMs module
	cd $(VM_DIR) && terragrunt init

plan: ## Plan VM changes
	cd $(VM_DIR) && terragrunt plan

apply: ## Apply VM changes
	cd $(VM_DIR) && terragrunt apply

destroy: ## Destroy VM resources (use with caution!)
	cd $(VM_DIR) && terragrunt destroy

# ---------------------------------------------------------------------------
# Import
# ---------------------------------------------------------------------------

import: ## Import existing VMs using declarative import blocks (just runs apply)
	@echo "Running apply with import blocks..."
	cd $(VM_DIR) && terragrunt apply

import-cli: ## Import existing VMs using CLI helper script
	./scripts/import-existing-vms.sh $(VM_DIR)

import-cli-dry: ## Dry-run the CLI import (shows commands without executing)
	./scripts/import-existing-vms.sh $(VM_DIR) --dry-run

# ---------------------------------------------------------------------------
# Run-all targets (all modules in a cluster)
# ---------------------------------------------------------------------------

plan-all: ## Plan all modules in the cluster
	cd $(DEPLOY_DIR) && terragrunt run-all plan

apply-all: ## Apply all modules in the cluster
	cd $(DEPLOY_DIR) && terragrunt run-all apply

# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------

fmt: ## Format all Terraform files
	terraform fmt -recursive Modules/

validate: ## Validate Terraform configuration
	cd $(VM_DIR) && terragrunt validate

console: ## Open Terraform console
	cd $(VM_DIR) && terragrunt console

state-list: ## List all resources in state
	cd $(VM_DIR) && terragrunt state list

state-show: ## Show a specific resource (usage: make state-show RES='nutanix_virtual_machine_v2.vm["name"]')
	cd $(VM_DIR) && terragrunt state show '$(RES)'

output: ## Show all outputs
	cd $(VM_DIR) && terragrunt output

# ---------------------------------------------------------------------------
# Lookup helpers
# ---------------------------------------------------------------------------

clusters: ## Fetch cluster name → ext_id mappings
	cd $(DEPLOY_DIR)/clusters && terragrunt apply -auto-approve && terragrunt output

networks: ## Fetch subnet name → ext_id mappings
	cd $(DEPLOY_DIR)/networks && terragrunt apply -auto-approve && terragrunt output

images: ## Fetch image name → ext_id mappings
	cd $(DEPLOY_DIR)/images && terragrunt apply -auto-approve && terragrunt output

# ---------------------------------------------------------------------------
# Config generation for imports
# ---------------------------------------------------------------------------

generate-config: ## Generate Terraform config for imported VMs (Terraform >= 1.5)
	@echo "Generating configuration for imported resources..."
	cd $(VM_DIR) && terragrunt plan -generate-config-out=generated_imports.tf
	@echo "Review generated_imports.tf and backport values to virtual_machines.yaml"
