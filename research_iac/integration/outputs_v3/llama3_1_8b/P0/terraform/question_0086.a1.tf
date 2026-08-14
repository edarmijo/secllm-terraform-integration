provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "traffic_policy_role" {
  name        = "route53_traffic_policy_role"
  description = "Role for Route 53 Traffic Policy"

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

resource "aws_iam_role_policy" "traffic_policy_policy" {
  name   = "route53_traffic_policy_policy"
  role   = aws_iam_role.traffic_policy_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "route53:GetTrafficPolicyInstance",
          "route53:UpdateTrafficPolicyInstance",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_route53_traffic_policy" "example" {
  name           = "example-traffic-policy"
  comment        = "Example traffic policy"
  provider_name  = "AWS"

  query_log_config {
    enabled = true
  }

  traffic_policy_document = jsonencode({
    Version = "2020-04-09",
    Id      = "example-traffic-policy-id",
    Statement = [
      {
        Effect = "Allow"
        Actions = [
          "route53:GetTrafficPolicyInstance",
          "route53:UpdateTrafficPolicyInstance",
        ]
        Resource = "*"
      }
    ]
  })
}