resource "aws_security_group" "default" {
  count       = var.create_security_group ? 1 : 0
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = var.vpc_name != "" ? data.aws_vpc.default[0].id : var.vpc_id
  tags        = var.security_group_tags
}

resource "aws_security_group_rule" "default" {
  for_each = var.create_security_group ? var.security_group_rules : {}

  type              = each.value.type
  description       = try(each.value.description, "")
  from_port         = try(each.value.from_port, -1)
  to_port           = try(each.value.to_port, -1)
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = var.create_security_group ? aws_security_group.default[0].id : data.aws_security_group.default[0].id
}

resource "aws_lb" "default" {
  count              = var.enabled ? 1 : 0
  name               = var.load_balancer_name == "" ? null : substr(var.load_balancer_name, 0, var.load_balancer_name_max_length)
  tags               = var.tags
  internal           = var.internal
  load_balancer_type = var.load_balancer_type

  security_groups = compact(
    concat([for sg in data.aws_security_group.selected : sg.id], [one(aws_security_group.default[*].id)]),
  )

  subnets = coalesce(var.subnet_ids, data.aws_subnet.default[*].id, [])

  enable_cross_zone_load_balancing = var.cross_zone_load_balancing_enabled
  enable_http2                     = var.http2_enabled
  idle_timeout                     = var.idle_timeout
  ip_address_type                  = var.ip_address_type
  enable_deletion_protection       = var.deletion_protection_enabled
  drop_invalid_header_fields       = var.drop_invalid_header_fields
  preserve_host_header             = var.preserve_host_header
  xff_header_processing_mode       = var.xff_header_processing_mode

  dynamic "access_logs" {
    for_each = length(var.access_logs) > 0 ? [var.access_logs] : []

    content {
      enabled = try(access_logs.value.enabled, try(access_logs.value.bucket, null) != null)
      bucket  = try(access_logs.value.bucket, null)
      prefix  = try(access_logs.value.prefix, null)
    }
  }

}

resource "aws_lb_listener" "this" {
  for_each = var.aws_lb_listeners

  load_balancer_arn = one(aws_lb.default[*].arn)

  port            = each.value.port
  protocol        = each.value.protocol
  ssl_policy      = each.value.protocol == "HTTPS" ? each.value.ssl_policy : null
  certificate_arn = each.value.certificate_arn
  tags            = each.value.listener_additional_tags

  default_action {
    target_group_arn = null
    type             = length(each.value.listener_fixed_response) > 0 ? "fixed-response" : "redirect"

    dynamic "fixed_response" {
      for_each = length(each.value.listener_fixed_response) > 0 ? each.value.listener_fixed_response : []
      content {
        content_type = fixed_response.value["content_type"]
        message_body = fixed_response.value["message_body"]
        status_code  = fixed_response.value["status_code"]
      }
    }

    dynamic "redirect" {
      for_each = length(each.value.listener_redirect) > 0 ? each.value.listener_redirect : []
      content {
        protocol    = redirect.value["protocol"]
        port        = redirect.value["port"]
        host        = redirect.value["host"]
        path        = redirect.value["path"]
        query       = lookup(redirect.value, "query", "")
        status_code = redirect.value["status_code"]
      }
    }
  }

}

resource "aws_lb_listener_certificate" "https_sni" {
  for_each = {
    for combo in local.listener_domain_combinations :
    "${combo.port}-${combo.domain_name}" => combo
  }

  listener_arn    = aws_lb_listener.this[each.value.port].arn
  certificate_arn = each.value.certificate_arn
}

