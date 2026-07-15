provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "reverse_zone" {
  name = "example53.com."
}

resource "aws_route53_record" "pointer_record" {
  zone_id = aws_route53_zone.reverse_zone.zone_id
  name    = "host.example53.com"
  type    = "PTR"
  ttl     = 300
  records = ["192.168.1.1"]
}