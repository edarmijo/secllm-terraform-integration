provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_record" "example" {
  name = "example.com"
  type = "A"
  alias {
    name = "d-1234567890.r53.amazonaws.com"
    zone_id = "Z01234567890"
  }
  ttl = 300
}