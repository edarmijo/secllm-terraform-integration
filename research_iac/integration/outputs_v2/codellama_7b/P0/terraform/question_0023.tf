provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "_amazonses"
  type    = "TXT"
  ttl     = 60
  records = ["passwordpassword"]
}

resource "aws_route53_zone" "example" {
  name = "example.com."
}