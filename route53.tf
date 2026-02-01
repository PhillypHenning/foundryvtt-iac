# Reference to existing Route53 hosted zone
data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

# Route53 A record pointing to ALB
resource "aws_route53_record" "foundryvtt_record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.subdomain_name}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.foundry_alb.dns_name
    zone_id                = aws_lb.foundry_alb.zone_id
    evaluate_target_health = true
  }
}
