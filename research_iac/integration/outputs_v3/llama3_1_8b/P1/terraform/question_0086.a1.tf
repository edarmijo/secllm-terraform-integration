provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

variable "name" {
  type        = string
  description = "Name for the Route 53 Traffic Policy"
}

resource "aws_iam_role" "route53_traffic_policy" {
  name        = "${var.name}-route53-traffic-policy-role"
  description = "Route 53 Traffic Policy IAM Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "route53.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "route53_traffic_policy" {
  name   = "${var.name}-route53-traffic-policy-policy"
  role   = aws_iam_role.route53_traffic_policy.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "route53:GetChange",
          "route53:ListTrafficPolicyInstancesByPolicy",
          "route53:ListTrafficPolicyInstances",
          "route53:UpdateTrafficPolicyInstance",
          "route53:CreateTrafficPolicyInstance",
          "route53:DeleteTrafficPolicyInstance"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "route53_traffic_policy" {
  name = "${var.name}-route53-traffic-policy-instance-profile"
  role = aws_iam_role.route53_traffic_policy.id
}

resource "aws_security_group" "route53_traffic_policy" {
  name        = "${var.name}-route53-traffic-policy-sg"
  description = "Route 53 Traffic Policy Security Group"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0/0"]
  }
}

resource "aws_route53_traffic_policy" "example" {
  name           = var.name
  comment        = "Route 53 Traffic Policy Example"
  template       = "AWS::Route53::TrafficPolicy::SimpleRoutingConfig"
  provider_id    = aws_iam_role.route53_traffic_policy.arn

  traffic_policy {
    id          = aws_route53_traffic_policy_instance.example.id
    name        = var.name
    comment     = "Route 53 Traffic Policy Example"
    type        = "FORWARD"
    routing_config {
      simple_routing_config {
        forwarding_config {
          target {
            domain_name = "example.com"
          }
        }
      }
    }
  }
}

resource "aws_route53_traffic_policy_instance" "example" {
  name           = var.name
  comment        = "Route 53 Traffic Policy Instance Example"
  traffic_policy_id = aws_route53_traffic_policy.example.id
  hosted_zone_id   = data.aws_caller_identity.current.account_id

  depends_on = [aws_security_group.route53_traffic_policy]
}