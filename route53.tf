#################
## DOMAIN NAME ##
#################
data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}
#################

#################
## DOMAIN NAME ##
#################
resource "aws_route53_record" "foundryvtt_record" {
  zone_id = data.aws_route53_zone.selected.zone_id

  name = "${var.subdomain_name}.${var.domain_name}"
  type = "A"
  ttl  = "300"

  # Associate the public IP of the EC2 instance
  # records = [aws_instance.foundry_instance.public_ip]
  records = [aws_eip.foundry_eip.public_ip]
}
#################


# resource "aws_route53_record" "foundryvtt_record" {
#   zone_id = data.aws_route53_zone.selected.zone_id
#   name    = "${var.subdomain_name}.${var.domain_name}"
#   type    = "A"
#   alias {
#     name                   = aws_lb.foundry_alb.dns_name
#     zone_id                = aws_lb.foundry_alb.zone_id
#     evaluate_target_health = true
#   }
# }
