provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

variable "name" {
  type        = string
  description = "Name for IAM role and policy"
}

variable "zone_id" {
  type        = string
  description = "Route 53 zone ID"
}

resource "aws_iam_role" "route53_zone_association" {
  name        = "${var.name}-route53-zone-association-role"
  description = "Route 53 zone association IAM role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
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

resource "aws_iam_role_policy" "route53_zone_association" {
  name   = "${var.name}-route53-zone-association-policy"
  role   = aws_iam_role.route53_zone_association.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "route53:AssociateVPCWithHostedZone",
          "route53:GetHostedZone",
          "route53:GetHealthCheck",
          "route53:GetHealthCheckConfig",
          "route53:GetHealthCheckObservation",
          "route53:GetHealthCheckStatus"
        ]
        Effect = "Allow"
        Resource = [
          "*"
        ]
      }
    ]
  })
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_route53_zone_association" "example" {
  zone_id = var.zone_id
  vpc_id  = aws_vpc.example.id
}