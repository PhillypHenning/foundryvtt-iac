# resource "aws_acm_certificate" "foundry_certificate" {
#   domain_name       = "${var.subdomain_name}.${var.domain_name}"
#   validation_method = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_record" "foundry_certificate_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.foundry_certificate.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       type   = dvo.resource_record_type
#       record = dvo.resource_record_value
#     }
#   }

#   zone_id = data.aws_route53_zone.selected.zone_id
#   name    = each.value.name
#   type    = each.value.type
#   ttl     = 60
#   records = [each.value.record]
# }

# resource "aws_acm_certificate_validation" "foundry_certificate_validation" {
#   certificate_arn         = aws_acm_certificate.foundry_certificate.arn
#   validation_record_fqdns = [for record in aws_route53_record.foundry_certificate_validation : record.fqdn]
# }

# resource "aws_lb" "foundry_alb" {
#   name               = "foundry-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.allow_specific_ips.id]
#   subnets            = [aws_instance.foundry_instance.subnet_id]

#   enable_deletion_protection = false
# }

# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.foundry_alb.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = aws_acm_certificate_validation.foundry_certificate_validation.certificate_arn

#   default_action {
#     type = "fixed-response"
#     fixed_response {
#       content_type = "text/plain"
#       message_body = "404: Not Found"
#       status_code  = "404"
#     }
#   }
# }

