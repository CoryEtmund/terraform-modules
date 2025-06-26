#####################################################################
# TF / Providers
#####################################################################

module aws_version {
    source = "../version"
}

terraform {
  required_providers {
    aws = {
      configuration_aliases = [ aws.backup ]
    }
  }
}

#####################################################################
# Data
#####################################################################
 
data "aws_vpc" "main" {
  #provider = aws.main
  for_each = var.directory_service
  filter {
    name   = "tag:Name"
    values = [each.value.vpc]
  }
}

data "aws_subnets" "main" {
  #provider = aws.main
  for_each = var.directory_service
  filter {
    values = [data.aws_vpc.main[each.key].id]
    name   = "vpc-id"
  }
}

data "aws_vpc" "backup" {
  provider = aws.backup
  for_each = var.directory_service
  filter {
    name   = "tag:Name"
    values = [each.value.vpc]
  }
}

data "aws_subnets" "backup" {
  provider = aws.backup
  for_each = var.directory_service
  filter {
    values = [data.aws_vpc.backup[each.key].id]
    name   = "vpc-id"
  }
}

#output "subnet_ids" {
#  value = local.subnet_ids
#  #value = data.aws_subnets.main["Managed-AD-1"]
#}

#####################################################################
# Resources
#####################################################################
 
# Primary AD deployment
resource "aws_directory_service_directory" "main" {
  #provider                             = aws.main
  for_each                             = var.directory_service
  name                                 = each.key
  alias                                = each.value.alias
  description                          = each.value.description
  password                             = each.value.password
  edition                              = each.value.edition
  type                                 = each.value.type
  desired_number_of_domain_controllers = each.value.domain_controller_count
  short_name                           = each.value.short_name
  enable_sso                           = each.value.enable_sso
 
  vpc_settings {
    vpc_id     = data.aws_vpc.main[each.key].id
    subnet_ids = data.aws_subnets.main[each.key].ids
  }
 
  #tags = {}
 
# In addition to all arguments above, the following attributes are exported:
  # id - The directory identifier.
  # access_url - The access URL for the directory, such as http://alias.awsapps.com.
  # dns_ip_addresses - A list of IP addresses of the DNS servers for the directory or connector.
  # security_group_id - The ID of the security group created by the directory.
  # tags_all - A map of tags assigned to the resource, including those inherited from the provider default_tags configuration block.
  # connect_settings (for ADConnector) is also exported with the following attributes:
  # connect_ips - The IP addresses of the AD Connector servers.
# aws_directory_service_directory provides the following Timeouts configuration options:
  # create - (Default 60 minutes) Used for directory creation
  # update - (Default 60 minutes) Used for directory update
  # delete - (Default 60 minutes) Used for directory deletion
}
 
 
#aws_directory_service_region # FOR MULTI-REGION REPLICATION
resource "aws_directory_service_region" "main" {
  for_each     = var.directory_service
  directory_id = aws_directory_service_directory.main[each.key].id
  region_name  = var.backup_region
  desired_number_of_domain_controllers = each.value.domain_controller_count
  vpc_settings {
    vpc_id     = data.aws_vpc.backup[each.key].id
    subnet_ids = data.aws_subnets.backup[each.key].ids
  }
}
 
 
#aws_directory_service_conditional_forwarder
 
 
#aws_directory_service_log_subscription
 
 
#aws_directory_service_radius_settings
 
 
#aws_directory_service_shared_directory
 
 
#aws_directory_service_shared_directory_accepter
 
 
#aws_directory_service_trust