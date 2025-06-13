module "networking" {
  # source of tf module
  source = "./networking"

  # required values for module
  vpc = var.vpc

  subnets = var.subnets

  internet_gateway_name = var.internet_gateway_name

  route_table_name = var.route_table_name
  route_table_cidr = var.route_table_cidr
}

module "security" {
  # source of tf module
  source = "./security_group"

  # required values for module
  security_group_name = var.security_group.security_group_name
  vpc_id = module.networking.vpc_id
  security_group_rules = var.security_group.rules
}

# Need to figure out how to call the subnet IDs correctly
#module "instances" {
#  # source of tf module
#  source = "./ec2_instances"
#
#  # required values for module
#  ami_ssm_paramater = var.ami_ssm_paramater
#  vpc_security_group_id = module.security.security_group_id
#
#  ec2s = {
#    instance_bob = {
#      instance_type = "t3.micro"
#      subnet_id = module.networking.subnets["subnet_1"].id
#    }
#    instance_joe = {
#      instance_type = "t3.micro"
#      subnet_id = module.networking.subnets["subnet_2"].id
#    }
#  }
#}
