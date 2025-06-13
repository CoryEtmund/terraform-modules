locals {
  ingress_rules = [ for v in var.security_group_rules: v if v.type == "ingress"]
  egress_rules  = [ for v in var.security_group_rules: v if v.type == "egress"]
}