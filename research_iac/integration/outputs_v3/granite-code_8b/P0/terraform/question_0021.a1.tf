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
    hosted_zone_id = "Z26RNL4JYFTOTI" # us-east-1 Route 53 Hosted Zone ID
    dns_name       = "ipv6.us-east-1.route53.amazonaws.com"
    evaluate_target_health = false
  }
}