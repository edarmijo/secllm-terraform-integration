provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_record" "ipv6_record" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "www"
  type    = "AAAA"
  ttl     = 300
  records = ["2001:db8::1"]
}