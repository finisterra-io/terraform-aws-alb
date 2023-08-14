locals {
  flattened_certs = flatten([
    for idx, listener in var.aws_lb_listeners :
    [for cert_name in lookup(listener, "additional_cert_names", []) :
      {
        index     = idx
        cert_name = cert_name
      }
    ]
  ])
}

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
  count = module.this.enabled && local.create_security_group == false ? 1 : 0
  name  = var.security_group_name
}

data "aws_acm_certificate" "main" {
  for_each = { for listener in var.aws_lb_listeners : listener.certificate_name => listener if listener.certificate_name != null }

  domain      = each.key # Assumes the name is the domain. Adjust if necessary.
  most_recent = true
}


data "aws_acm_certificate" "additional" {
  for_each = { for item in local.flattened_certs : "${item.index}-${item.cert_name}" => item }

  domain      = each.value.cert_name
  most_recent = true
}
