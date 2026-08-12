provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_secretsmanager_secret" "private_zone_secret" {
  name        = "private-zone-secret"
  description = "Secret for private Route53 zone"
}

resource "aws_secretsmanager_secret_version" "private_zone_secret_version" {
  secret_id     = aws_secretsmanager_secret.private_zone_secret.id
  secret_string = jsonencode({
    hosted_zone_name = var.private_zone_name
  })
}

data "aws_region" "current" {}

resource "aws_route53_zone" "private_zone" {
  name            = var.private_zone_name
  vpc_id          = aws_vpc.main.id
  private_zone    = true

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "Main VPC"
    Environment = var.environment
  }
}

resource "aws_route53_record" "private_zone_record" {
  zone_id = aws_route53_zone.private_zone.id
  name    = var.private_zone_name
  type    = "NS"

  alias {
    name                   = aws_vpc.main.dns_support_enabled ? aws_vpc.main.dns_name : null
    zone_id                = aws_vpc.main.dns_support_enabled ? data.aws_region.current.name : null
    evaluate_target_health = false
  }
}

resource "aws_iam_role" "private_zone_role" {
  name        = "PrivateZoneRole"
  description = "Role for private Route53 zone"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "private_zone_policy" {
  name   = "PrivateZonePolicy"
  role   = aws_iam_role.private_zone_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:GetHostedZone",
          "route53:GetHealthCheck",
          "route53:GetHealthCheckConfig",
          "route53:GetHealthCheckObservation",
          "route53:GetHealthCheckStatus",
          "route53:GetHealthCheckStatistics",
        ]
        Resource = aws_route53_zone.private_zone.id
        Effect    = "Allow"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "private_zone_profile" {
  name = "PrivateZoneProfile"

  role = aws_iam_role.private_zone_role.name
}