variable "ami_ssm_paramater" {
  type = string
}

variable "vpc_security_group_id" {
  type = string
}

variable "ec2s" {
  type = map(object({
    instance_type = string
    subnet_id = string
  }))
}