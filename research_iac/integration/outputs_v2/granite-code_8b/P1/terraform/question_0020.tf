provider "aws" {
  region = var.region
}

resource "aws_route53_zone" "example" {
  name = var.domain_name
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.id
  name    = var.record_name
  type    = "A"

  alias_target {
    hosted_zone_id = "Z26RNL4JYFTOTI" # replace with the appropriate value
    dns_name       = "example-elb-1234567890.us-east-1.elb.amazonaws.com" # replace with the appropriate value
    evaluate_target_health = false
  }
}