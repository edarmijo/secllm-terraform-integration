provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_record" "example" {
  zone_id = "ZONE_ID"
  name    = "example.com"
  type    = "AAAA"
  ttl     = 60
  records = ["2001:db8::1"]
}