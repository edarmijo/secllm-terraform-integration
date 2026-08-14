resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "example.com"
  type    = "AAAA"
  ttl     = 60
  records = ["2001:db8::1"]
}