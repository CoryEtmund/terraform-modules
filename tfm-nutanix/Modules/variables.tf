variable "nutanix_username" {
  description = "Username for Nutanix Prism Central API"
  type        = string
}

variable "nutanix_password" {
  description = "Password for Nutanix Prism Central API"
  type        = string
  sensitive   = true
}

variable "nutanix_endpoint" {
  description = "Nutanix Prism Central endpoint"
  type        = string
}

variable "nutanix_port" {
  description = "Port for Nutanix Prism Central API (default: 9440)"
  type        = number
  default     = 9440
}

variable "nutanix_insecure" {
  description = "Whether to ignore SSL certificate validation"
  type        = bool
  default     = true
}