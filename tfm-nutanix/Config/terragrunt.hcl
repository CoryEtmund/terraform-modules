###############################################################################
# Root Terragrunt Configuration — Nutanix Deployment
#
# This file lives alongside the YAML config files and wires everything
# together: reads YAML data, configures the remote state backend, generates
# the provider block, and points Terraform at the correct module.
###############################################################################

# ---------------------------------------------------------------------------
# Locals — load all YAML configuration files
# ---------------------------------------------------------------------------
locals {
  virtual_machines_config = yamldecode(file(find_in_parent_folders("virtual_machines.yaml")))
  clusters_config         = yamldecode(file(find_in_parent_folders("clusters.yaml")))
  networks_config         = yamldecode(file(find_in_parent_folders("networks.yaml")))
  images_config           = yamldecode(file(find_in_parent_folders("images.yaml")))

  # Read environment-specific overrides if present
  env_config = try(yamldecode(file("env.yaml")), {})
}

# ---------------------------------------------------------------------------
# Terraform source — point to the Modules directory
# ---------------------------------------------------------------------------
terraform {
  source = "${get_parent_terragrunt_dir()}/../Modules//${path_relative_to_include()}/"

  # Recommended: copy the shared provider.tf and variables.tf into the module
  # working directory so each sub-module inherits the provider configuration.
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()
  }
}

# ---------------------------------------------------------------------------
# Remote State — S3 Backend (adjust to your environment)
# ---------------------------------------------------------------------------
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = get_env("TG_STATE_BUCKET", "nutanix-terraform-state")
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = get_env("TG_STATE_REGION", "us-east-1")
    encrypt        = true
    dynamodb_table = get_env("TG_STATE_LOCK_TABLE", "nutanix-terraform-locks")
  }
}

# ---------------------------------------------------------------------------
# Generate provider file — so each module gets the provider automatically
# ---------------------------------------------------------------------------
generate "provider" {
  path      = "provider_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.5.0"

      required_providers {
        nutanix = {
          source  = "nutanix/nutanix"
          version = ">= 2.0.0, < 3.0.0"
        }
      }
    }

    provider "nutanix" {
      username     = var.nutanix_username
      password     = var.nutanix_password
      endpoint     = var.nutanix_endpoint
      port         = var.nutanix_port
      insecure     = var.nutanix_insecure
      session_auth = var.nutanix_session_auth
      wait_timeout = var.nutanix_wait_timeout
      proxy_url    = var.nutanix_proxy_url
    }

    variable "nutanix_username" {
      description = "Username for Nutanix Prism Central API."
      type        = string
    }

    variable "nutanix_password" {
      description = "Password for Nutanix Prism Central API."
      type        = string
      sensitive   = true
    }

    variable "nutanix_endpoint" {
      description = "Nutanix Prism Central IP address or FQDN."
      type        = string
    }

    variable "nutanix_port" {
      description = "Port for Nutanix Prism Central API."
      type        = number
      default     = 9440
    }

    variable "nutanix_insecure" {
      description = "Whether to skip SSL certificate verification."
      type        = bool
      default     = true
    }

    variable "nutanix_session_auth" {
      description = "Use session-based authentication."
      type        = bool
      default     = true
    }

    variable "nutanix_wait_timeout" {
      description = "Timeout in minutes for resource operations."
      type        = number
      default     = 10
    }

    variable "nutanix_proxy_url" {
      description = "Proxy URL for Nutanix Prism Central."
      type        = string
      default     = null
    }
  EOF
}

# ---------------------------------------------------------------------------
# Inputs — merge all YAML data + provider credentials
# ---------------------------------------------------------------------------
inputs = merge(
  local.virtual_machines_config,
  local.clusters_config,
  local.networks_config,
  local.images_config,
  local.env_config,
  {
    # Provider credentials — sourced from environment variables
    nutanix_username     = get_env("NUTANIX_USERNAME", "")
    nutanix_password     = get_env("NUTANIX_PASSWORD", "")
    nutanix_endpoint     = get_env("NUTANIX_ENDPOINT", "")
    nutanix_port         = tonumber(get_env("NUTANIX_PORT", "9440"))
    nutanix_insecure     = tobool(get_env("NUTANIX_INSECURE", "true"))
    nutanix_session_auth = tobool(get_env("NUTANIX_SESSION_AUTH", "true"))
    nutanix_wait_timeout = tonumber(get_env("NUTANIX_WAIT_TIMEOUT", "10"))
    nutanix_proxy_url    = get_env("NUTANIX_PROXY_URL", "")
  }
)
