data "aws_ssm_parameter" "windows_ami" {
  name = var.ami_ssm_paramater
}

resource "aws_instance" "main" {
  for_each = var.ec2s
  ami = nonsensitive(data.aws_ssm_parameter.windows_ami.value)
  instance_type = each.value.instance_type
  subnet_id = each.value.subnet_id
  vpc_security_group_ids = [var.vpc_security_group_id]

  tags = {
    Name = each.key
  }
}