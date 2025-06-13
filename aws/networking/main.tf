resource "aws_vpc" "main" {
  cidr_block           = var.vpc.cidr_block
  enable_dns_hostnames = var.vpc.enable_dns_hostnames

  tags = {
    Name = var.vpc.name
  }
}

resource "aws_subnet" "main" {
  for_each = var.subnets
  cidr_block = each.value.cidr_block
  availability_zone = each.value.availability_zone
  vpc_id = aws_vpc.main.id

  tags = {
    name = each.key
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.internet_gateway_name
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.route_table_cidr
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = var.route_table_name
  }
}

resource "aws_route_table_association" "main" {
  for_each = var.subnets
  subnet_id = aws_subnet.main[each.key].id
  route_table_id = aws_route_table.main.id
}