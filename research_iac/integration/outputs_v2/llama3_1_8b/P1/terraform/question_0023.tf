provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "route53_verification" {
  name        = "${var.zone_name}-route53-verification"
  description = "Route 53 TXT record for domain ownership verification"

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

resource "aws_iam_role_policy" "route53_verification" {
  name   = "${var.zone_name}-route53-verification-policy"
  role   = aws_iam_role.route53_verification.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "route53:ChangeResourceRecordSets"
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_route53_zone" "example" {
  name            = var.zone_name
  delegation_set_id = aws_route53_delegation_set.example.id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_delegation_set" "example" {
  name           = "${var.zone_name}-delegation-set"
  caller_reference = data.aws_caller_identity.current.account_id
}

resource "aws_route53_record" "txt_record" {
  zone_id = aws_route53_zone.example.id
  name    = "_amazonses.${var.zone_name}"
  type    = "TXT"
  ttl     = "300"
  records = ["passwordpassword"]
}