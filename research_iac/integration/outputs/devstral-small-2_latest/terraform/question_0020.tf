provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "example.com"
  type    = "A"
  ttl     = 300
  records = ["192.0.2.1"]
}