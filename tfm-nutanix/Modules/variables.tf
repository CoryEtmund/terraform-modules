###############################################################################
# Nutanix Provider Variables
###############################################################################

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
  description = "Use session-based authentication (cookie) for improved performance."
  type        = bool
  default     = true
}

variable "nutanix_wait_timeout" {
  description = "Timeout in minutes for resource operations."
  type        = number
  default     = 10
}

variable "nutanix_proxy_url" {
  description = "Proxy URL to use for connecting to Nutanix Prism Central."
  type        = string
  default     = null
}
