#provider "aws" {
#  region = "us-east-1"
#  alias = "us-east-1"
#}
#
#provider "aws" {
#  region = "us-east-2"
#  alias = "us-east-2"
#}
#
#provider "aws" {
#  region = "us-east-1"
#  alias = "UE1"
#}
#
#provider "aws" {
#  region = "us-east-2"
#  alias = "UE2"
#}
#
#locals {
#  provider_alias = "aws.${var.region}"
#}

provider "aws" {
  region = var.region
}

module "networking" {
  source = "../networking"
  vpc = var.vpc
  #providers = {
  #  aws = aws.us-east-1
  #}
}

module "directory_service" {
  count = var.directory_service != null ? 1 : 0
  source = "../directory-service"
  directory_service = var.directory_service
  depends_on = [ module.networking ]
}

#module "networking2" {
#  source = "../networking"
#  vpc = var.vpc
#  providers = {
#    aws = aws.UE2
#  }
#}