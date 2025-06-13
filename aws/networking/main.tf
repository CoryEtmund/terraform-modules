resource "aws_vpc" "main" {
  for_each   = var.vpc
  cidr_block = each.value.cidr_block

  tags = {
    Name = each.key
  }
}

resource "aws_subnet" "main" {
  for_each = {
    for v in local.subnets : "${v.vpc_name}_${v.subnet_name}" => v
  }
  vpc_id            = each.value.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  tags = {
    Name = each.key
  }
}

resource "aws_internet_gateway" "main" {
  for_each = {
    for vpc_name, vpc in var.vpc : vpc_name => vpc
    if vpc.internet_gateway != null && vpc.internet_gateway != ""
  }
  vpc_id = aws_vpc.main[each.key].id
  tags = {
    Name = "${each.key}_${each.value.internet_gateway}"
  }
}

resource "aws_route_table" "main" {
  for_each = {
    for vpc_name, vpc in var.vpc : vpc_name => vpc
    if vpc.route_table != null && vpc.route_table != ""
  }
  vpc_id = aws_vpc.main[each.key].id
  tags = {
    Name = "${each.key}_${each.value.route_table}"
  }
}

resource "aws_route_table_association" "main" {
  for_each = {
    for v in local.subnets : "${v.vpc_name}_${v.subnet_name}" => v
  }
  subnet_id      = aws_subnet.main[each.key].id
  route_table_id = aws_route_table.main[each.value.vpc_name].id
}