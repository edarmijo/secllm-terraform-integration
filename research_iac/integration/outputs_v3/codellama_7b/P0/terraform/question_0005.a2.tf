resource "aws_route53_record" "weighted_routing_policy" {
  name    = "main"
  type    = "A"
  ttl     = 60
  records = ["primary", "replica-1", "replica-2"]
}