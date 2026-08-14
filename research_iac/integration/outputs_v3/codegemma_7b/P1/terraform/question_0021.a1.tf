provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_record" "example" {
  name = "example.com"
  type = "A"
  alias {
    name = "ipv6.amazonaws.com"
    zone_id = "Z2FDTNDATAQYW2"
    evaluate_target_health = true
  }
}