provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name = "example.com."
}

resource "aws_lb" "main" {
  name               = "main-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = []
  subnets            = []
}

resource "aws_route53_record" "main" {
  name    = "main.example.com."
  zone_id = aws_route53_zone.primary.zone_id
  type    = "A"
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                 = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}