provider "aws" {
  region = "us-west-2"
}

resource "aws_route53_zone" "example" {
  name = "example."
}

resource "aws_route53_record" "txt_record" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "_acme-challenge.example."
  type    = "TXT"
  ttl     = "300"
  records = ["passwordpassword"]
}