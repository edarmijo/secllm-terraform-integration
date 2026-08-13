provider "aws" {
  region = "us-west-2"
}

resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "example.com"
  type    = "A"
  alias {
    name                   = "s3-website-us-west-2.amazonaws.com"
    zone_id                = "Z2BJ6XLDIX7F1F"
    evaluate_target_health = false
  }
}

resource "aws_iam_role" "route53_access" {
  name        = "Route53AccessRole"
  description = "Allows Route 53 to access S3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "route53.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "route53_access_policy" {
  name        = "Route53AccessPolicy"
  description = "Allows Route 53 to access S3"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:GetObject"]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "route53_access_attach" {
  role       = aws_iam_role.route53_access.name
  policy_arn = aws_iam_policy.route53_access_policy.arn
}