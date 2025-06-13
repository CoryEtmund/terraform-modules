locals {
  subnets = flatten([
    for vpc_name, vpc in var.vpc : [
      for subnet_name, subnet in vpc.subnets : {
        vpc_name          = vpc_name
        subnet_name       = subnet_name
        vpc_id            = aws_vpc.main[vpc_name].id
        cidr_block        = subnet.cidr_block
        availability_zone = subnet.availability_zone
      }
    ]
  ])
}
