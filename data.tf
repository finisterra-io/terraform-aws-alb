
data "aws_vpc" "default" {
  count = module.this.enabled && var.vpc_name != "" ? 1 : 0
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnet" "default" {
  count  = module.this.enabled && var.subnet_names != [] ? length(var.subnet_names) : 0
  vpc_id = data.aws_vpc.default[0].id
  filter {
    name   = "tag:Name"
    values = [var.subnet_names[count.index]]
  }
}

data "aws_security_group" "default" {
  count = module.this.enabled && var.create_security_group == false ? 1 : 0
  name  = var.security_group_name
}

data "aws_acm_certificate" "main" {
  for_each = { for listener in var.aws_lb_listeners : listener.domain_name => listener if listener.domain_name != null }

  domain      = each.key # Assumes the name is the domain. Adjust if necessary.
  most_recent = true
}

data "aws_acm_certificate" "additional" {
  for_each = { for cert_name in var.aws_lb_listener_certificates : cert_name => cert_name }

  domain      = each.value
  most_recent = true
}

data "aws_security_group" "selected" {
  count = length(var.security_group_names)
  name  = var.security_group_names[count.index]
}
