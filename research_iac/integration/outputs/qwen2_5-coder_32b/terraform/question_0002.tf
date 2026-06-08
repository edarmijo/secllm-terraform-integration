provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "elb_service_linked_role" {
  name = "AWSServiceRoleForElasticLoadBalancing"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticloadbalancing.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_lb" "main" {
  name               = "main"
  internal           = false
  load_balancer_type = "application"

  subnets = ["subnet-12345678", "subnet-87654321"]

  tags = {
    Name = "main"
  }
}

resource "aws_route53_zone" "primary" {
  name = "example.com."
}

resource "aws_route53_record" "elb_dns" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}