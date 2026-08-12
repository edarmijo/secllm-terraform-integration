provider "aws" {
  region = "us-east-1"
}

data "aws_route53_zone" "example" {
  name = "example.com."
  access_key = "<YOUR_ACCESS_KEY>"
  secret_key = "<YOUR_SECRET_KEY>"
}

resource "aws_route53_record" "example" {
  zone_id = data.aws_route53_zone.example.zone_id
  name    = "example.com"
  type    = "A"
  ttl     = 60
  records = ["192.0.2.1"]
}