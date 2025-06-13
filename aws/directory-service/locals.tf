locals {
    subnets_ids = [ for v in data.data.aws_subnet.main : v.id ]
}

#locals {
#  ingress_rules = [ for v in var.security_group_rules: v if v.type == "ingress"]
#  egress_rules  = [ for v in var.security_group_rules: v if v.type == "egress"]
#}