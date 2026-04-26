data "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_route53_record" "foundryvtt" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.subdomain_name}.${var.domain_name}"
  type    = "A"
  ttl     = 60
  records = [aws_eip.foundryvtt.public_ip]
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  ttl     = 60
  records = [aws_eip.foundryvtt.public_ip]
}
