variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc" {
  type = map(object({
    cidr_block = string
    internet_gateway = string
    route_table      = string
    enable_dns_hostnames = optional(bool, true)
    subnets = map(object({
      cidr_block        = string
      availability_zone = string
    }))
  }))
}

variable "directory_service" {
  type = map(object({
    alias                   = string
    description             = optional(string, "")
    type                    = optional(string, "MicrosoftAD")
    password                = string
    edition                 = optional(string, "Enterprise")
    domain_controller_count = optional(number, 2)
    short_name              = optional(string, "")
    enable_sso              = optional(bool, false)
  }))
  default = null
}
