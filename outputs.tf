output "alb_name" {
  description = "The ARN suffix of the ALB"
  value       = one(aws_lb.default[*].name)
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = one(aws_lb.default[*].arn)
}

output "alb_arn_suffix" {
  description = "The ARN suffix of the ALB"
  value       = one(aws_lb.default[*].arn_suffix)
}

output "alb_dns_name" {
  description = "DNS name of ALB"
  value       = one(aws_lb.default[*].dns_name)
}

output "alb_zone_id" {
  description = "The ID of the zone which ALB is provisioned"
  value       = one(aws_lb.default[*].zone_id)
}

# output "security_group_id" {
#   description = "The security group ID of the ALB"
#   value       = one(aws_security_group.default[*].id)
# }

