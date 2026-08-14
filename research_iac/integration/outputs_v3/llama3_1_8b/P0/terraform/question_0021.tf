provider "aws" {
  region = "us-west-2"
}

resource "aws_route53_zone" "example" {
  name = "example.com."
}

resource "aws_route53_record" "ipv6_mapping" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "www.example.com."
  type    = "AAAA"
  ttl     = "300"
  records = ["2001:0db8:85a3:0000:0000:8a2e:0370:7334"]
}

resource "aws_iam_role" "route53_service_linked_role" {
  name        = "Route53ServiceLinkedRole"
  description = "Service-linked role for Route 53"

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

resource "aws_iam_role_policy" "route53_policy" {
  name   = "Route53Policy"
  role   = aws_iam_role.route53_service_linked_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:GetChange",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}