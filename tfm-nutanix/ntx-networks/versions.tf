###############################################################################
# Terraform & Provider Version Constraints
###############################################################################

terraform {
  required_version = ">= 1.5.0" # Required for declarative import blocks

  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = ">= 2.0.0, < 3.0.0" # v4 API (nutanix_subnet_v2)
    }
  }
}
