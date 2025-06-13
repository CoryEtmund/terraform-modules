variable "vpc" {
  description = "VPC configuration"
  type        = object({
    name                   = string
    cidr_block             = string
    enable_dns_hostnames   = optional(bool, true)
  })
}

variable "subnets" {
  description = "Map of subnets configuration"
  type        = map(object({
    availability_zone = string
    cidr_block        = string
  }))
}

variable "internet_gateway_name" {
  description = "Name of the internet gateway"
  type        = string  
}

variable "route_table_name" {
  description = "Name of the route table"
  type        = string  
}

variable "route_table_cidr" {
  description = "CIDR block for the route table"
  type        = string
}

variable "security_group" {
  description = "Security group configuration"
  type        = object({
    security_group_name   = string
    vpc_id                = string
    rules                 = list(object({
      type        = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
  })
}

#variable "ami_ssm_paramater" {
#  description = "SSM parameter for the AMI"
#  type        = string
#}