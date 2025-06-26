module aws_version {
    source = "../version"
}

provider "aws" {
  region = var.region
}

provider "aws" {
  region = var.backup_region
  alias  = "backup"
}

module "networking" {
  source = "../networking"
  vpc    = var.vpc
}

module "directory_service" {
  count              = var.directory_service != null ? 1 : 0
  source             = "../directory-service"
  directory_service  = var.directory_service
  backup_region      = var.backup_region != null ? var.backup_region : null
  depends_on         = [module.networking]
  providers = {
    aws.backup = aws.backup
  }
}
