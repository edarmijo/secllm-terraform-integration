provider "aws" {
  region = var.region
}

resource "aws_route53_zone" "primary" {
  name = "example.com"
}

resource "aws_route53_record" "primary_a_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www"
  type    = "A"

  alias_target {
    hosted_zone_id = "Z26RNL4JYFTOTI" # US East (Ohio)
    dns_name       = "us-east-1-elb.amazonaws.com"
    evaluate_target_health = true
  }
}