provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "example_zone" {
  name = "example.com"
}

resource "aws_route53_record" "txt_record" {
  zone_id = aws_route53_zone.example_zone.zone_id
  name    = "_acme-challenge.example.com"
  type    = "TXT"
  ttl     = 60
  records = ["\"passwordpassword\""]
}