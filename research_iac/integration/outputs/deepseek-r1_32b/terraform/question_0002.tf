provider "aws" {
  region = var.region
}

resource "aws_elb" "main" {
  name               = "main"
  listener {
    # Define listeners as needed
  }
  instances = []
}

resource "aws_route53_zone" "primary" {
  name = "primary."
}

resource "aws_route53_record" "elb_record" {
  zone_id = aws_route53_zone.primary.id
  type    = "CNAME"
  name    = "*.${var.domain}"
  ttl     = "300"
  records = [aws_elb.main.dns_name]
}

variable "region" {
  description = "AWS region for deployment"
  default     = "us-west-2"
}

variable "domain" {
  description = "Domain name for the Route53 zone"
  default     = "example.com"
}