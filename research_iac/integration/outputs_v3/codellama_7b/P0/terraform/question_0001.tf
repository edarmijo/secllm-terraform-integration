resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.id
  name    = "www.example.com"
  type    = "A"
  ttl     = 60
  records = ["192.0.2.1"]
}