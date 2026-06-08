provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_record" "ipv6_aaaa" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "subdomain.example.com"
  type    = "AAAA"
  ttl     = 300
  records = ["2001:0db8:85a3::8a2e:0370:7334"]
}