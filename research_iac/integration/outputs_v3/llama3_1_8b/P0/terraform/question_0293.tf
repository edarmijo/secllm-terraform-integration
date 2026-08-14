provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "s3_access_logs_role" {
  name        = "S3AccessLogsRole"
  description = "Allows the S3 service to write access logs to a second bucket"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_access_logs_policy" {
  name   = "S3AccessLogsPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_logs_attach" {
  role       = aws_iam_role.s3_access_logs_role.name
  policy_arn = aws_iam_policy.s3_access_logs_policy.arn
}

resource "aws_s3_bucket" "example_bucket" {
  bucket = "example-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "access-logs-bucket"
    target_prefix = "s3-access-logs/"
  }
}

resource "aws_s3_bucket" "access_logs_bucket" {
  bucket = "access-logs-bucket"
}