###############################################################################
# Root Terragrunt Configuration — Nutanix Deployments
#
# All child terragrunt.hcl files will inherit from this root.
# This configures the remote state backend and shared provider credentials.
###############################################################################

locals {
  # Parse environment-specific config from child directories
  env_config = try(yamldecode(file("${get_terragrunt_dir()}/env.yaml")), {})
}

# ---------------------------------------------------------------------------
# Remote State — S3 Backend (adjust bucket/region to your environment)
# ---------------------------------------------------------------------------
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = get_env("TG_STATE_BUCKET", "nutanix-terraform-state")
    key            = "nutanix/${path_relative_to_include()}/terraform.tfstate"
    region         = get_env("TG_STATE_REGION", "us-east-1")
    encrypt        = true
    dynamodb_table = get_env("TG_STATE_LOCK_TABLE", "nutanix-terraform-locks")
  }
}

# ---------------------------------------------------------------------------
# Generate — Provider block injected into every child module
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
# Shared inputs — provider credentials from environment variables
# ---------------------------------------------------------------------------
inputs = {
  nutanix_username     = get_env("NUTANIX_USERNAME", "")
  nutanix_password     = get_env("NUTANIX_PASSWORD", "")
  nutanix_endpoint     = get_env("NUTANIX_ENDPOINT", "")
  nutanix_port         = tonumber(get_env("NUTANIX_PORT", "9440"))
  nutanix_insecure     = tobool(get_env("NUTANIX_INSECURE", "true"))
  nutanix_session_auth = tobool(get_env("NUTANIX_SESSION_AUTH", "true"))
  nutanix_wait_timeout = tonumber(get_env("NUTANIX_WAIT_TIMEOUT", "10"))
  nutanix_proxy_url    = get_env("NUTANIX_PROXY_URL", "")
}
