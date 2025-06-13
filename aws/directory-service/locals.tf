locals {
    subnets_ids = data.aws_subnet.main[*].id
}