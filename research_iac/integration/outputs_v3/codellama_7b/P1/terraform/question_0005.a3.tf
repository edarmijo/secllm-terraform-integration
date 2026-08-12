resource "aws_route53_record" "weighted_routing" {
  name    = "main.example.com"
  type    = "A"
  ttl     = 60
  records = ["primary.example.com", "replica-1.example.com", "replica-2.example.com"]
  zone_id = aws_route53_zone.main.zone_id
}

resource "aws_route53_record" "weighted_routing_policy" {
  name    = "main.example.com"
  type    = "A"
  ttl     = 60
  records = ["primary.example.com", "replica-1.example.com", "replica-2.example.com"]
  zone_id = aws_route53_zone.main.zone_id
}

resource "aws_route53_zone" "main" {
  name    = "example.com"
  comment = "Main Route53 Zone"
}