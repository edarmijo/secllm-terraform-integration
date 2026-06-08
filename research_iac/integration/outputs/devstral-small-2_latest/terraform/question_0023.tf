provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_record" "verification" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "_amazonses.example.com"
  type    = "TXT"
  ttl     = 300
  records = ["\"passwordpassword\""]
}