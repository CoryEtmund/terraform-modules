variable "security_group_name" {
  type = string
}

variable "vpc_id" {
  type = string 
}

variable "security_group_rules" {
  type = list(object({
    from_port = number
    to_port = number
    protocol = string
    cidr_blocks = list(string)
    type = string
  }))
}