#####################################################################
# TF/Provider configuration
#####################################################################
 
# (terraform.tf)
module aws_version {
    source = "../version"
}
 
#####################################################################
# Data
#####################################################################
 
data "aws_vpc" "main" {}
data "aws_subnet" "main" {}
 
#####################################################################
# Resources
#####################################################################
 
# Primary AD deployment
resource "aws_directory_service_directory" "main" {
  name        = var.name
  alias       = var.alias
  description = var.description
  # region    = var.region # "us-east-1" # defaults to region set in provider if not set here # NOT AVAILABLE IN THIS PROVIDER VERSION
  password    = "test"
  edition     = var.edition
  type        = var.type
  desired_number_of_domain_controllers = var.domain_controller_count
  short_name  = var.short_name
  enable_sso  = var.enable_sso
 
  vpc_settings {
    vpc_id     = data.aws_vpc.main.id                                                    # NEEDS UPDATED TO GET CORRECT VPC
    subnet_ids = local.subnets_ids               # NEEDS UPDATED TO GET CORRECT SUBNETS
  }
 
  #tags = {}
 
#desired_number_of_domain_controllers - (Optional)
#short_name - (Optional)
#enable_sso - (Optional)
#alias - (Optional)
#description - (Optional)
#vpc_settings - (Required for SimpleAD and MicrosoftAD)
#region – (Optional)
#type (Optional)
#edition - (Optional, for type MicrosoftAD only) (Standard or Enterprise)
#tags - (Optional)
 
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
#resource "aws_directory_service_region" "main" {
#
#}
 
 
#aws_directory_service_conditional_forwarder
 
 
#aws_directory_service_log_subscription
 
 
#aws_directory_service_radius_settings
 
 
#aws_directory_service_shared_directory
 
 
#aws_directory_service_shared_directory_accepter
 
 
#aws_directory_service_trust