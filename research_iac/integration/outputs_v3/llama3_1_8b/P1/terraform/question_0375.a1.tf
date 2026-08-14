provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "bucket_arn" {
  type        = string
  description = "ARN of the bucket"
}

variable "bucket_name" {
  type        = string
  description = "Name of the bucket"
}

resource "aws_iam_role" "lightsail_resource_access" {
  name        = "${var.environment}-LightsailResourceAccess"
  description = "Allows Lightsail to access the bucket"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lightsail.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "lightsail_resource_access" {
  name   = "${var.environment}-LightsailResourceAccessPolicy"
  role   = aws_iam_role.lightsail_resource_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Effect = "Allow"
        Resource = var.bucket_arn
      },
    ]
  })
}

resource "aws_s3_bucket_policy" "example" {
  bucket = var.bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Effect = "Allow"
        Principal = {
          Service = "lightsail.amazonaws.com"
        }
        Resource = var.bucket_arn
      },
    ]
  })
}