#locals {
  #subnet_ids = data.aws_subnets.main
  #subnet_ids = [ for v in data.aws_subnets.main : v.ids ]
#}

#locals {
#  ingress_rules = [ for v in var.security_group_rules: v if v.type == "ingress"]
#  egress_rules  = [ for v in var.security_group_rules: v if v.type == "egress"]
#}