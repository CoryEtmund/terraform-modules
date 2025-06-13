variable "vpc" {
  type = object({
    name = string
    cidr_block = string
    enable_dns_hostnames = bool
  })
}

variable "subnets" {
  type = map(object({
    cidr_block = string
    availability_zone = string
  }))
}

variable "internet_gateway_name" {
  type = string
}

variable "route_table_name" {
  type = string
}

variable "route_table_cidr" {
  type = string
}