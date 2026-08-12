provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_record" "example" {
  zone_id = "<YOUR ZONE ID>"
  name    = "example.com"
  type    = "A"
  ttl     = 60
  records = ["<IPv4 ADDRESS>"]
}