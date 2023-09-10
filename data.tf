
data "aws_vpc" "default" {
  count = module.this.enabled && var.vpc_name != "" ? 1 : 0
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnet" "default" {
  count  = module.this.enabled && var.subnet_names != null ? length(var.subnet_names) : 0
  vpc_id = var.vpc_name != "" ? data.aws_vpc.default[0].id : var.vpc_id
  filter {
    name   = "tag:Name"
    values = [var.subnet_names[count.index]]
  }
}

data "aws_security_group" "default" {
  count = module.this.enabled && var.security_group_name != null && var.create_security_group == false ? 1 : 0
  name  = var.security_group_name
}

data "aws_acm_certificate" "main" {
  for_each = {
    for listener in var.aws_lb_listeners : listener.acm_domain_name => listener if listener.acm_domain_name != null && listener.acm_domain_name != ""
  }

  domain      = each.key # Assumes the name is the domain. Adjust if necessary.
  most_recent = true
}

data "aws_acm_certificate" "additional" {
  for_each = toset(flatten([for listener in var.aws_lb_listeners : listener.all_acm_domains]))

  domain      = each.key
  most_recent = true
}


data "aws_security_group" "selected" {
  count = length(var.security_group_names)
  name  = var.security_group_names[count.index]
}
