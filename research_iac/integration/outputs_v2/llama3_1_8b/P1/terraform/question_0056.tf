provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_kinesis_stream" "example" {
  name        = var.stream_name
  shard_count = 1
  encryption {
    key_id      = aws_kms_key.example.arn
    type        = "KMS"
  }
}

resource "aws_kms_key" "example" {
  description             = "Kinesis Stream Encryption Key"
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Allow Kinesis to use the key"
        Effect    = "Allow"
        Action    = ["kms:Encrypt", "kms:ReEncrypt", "kms:GenerateDataKey"]
        Resource  = aws_kinesis_stream.example.arn
        Principal {
          Service = "kinesis.amazonaws.com"
        }
      },
      {
        Sid       = "Allow IAM to use the key for cross-account access"
        Effect    = "Allow"
        Action    = ["kms:Encrypt", "kms:ReEncrypt", "kms:GenerateDataKey"]
        Resource  = aws_kinesis_stream.example.arn
        Principal {
          Service = "iam.amazonaws.com"
        }
      },
      {
        Sid       = "Enable key rotation"
        Effect    = "Allow"
        Action    = ["kms:CreateAlias", "kms:DeleteAlias"]
        Resource  = aws_kinesis_stream.example.arn
      }
    ]
  })
}

resource "aws_iam_role" "example" {
  name               = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Allow Kinesis to use the role"
        Effect    = "Allow"
        Action    = ["sts:AssumeRole"]
        Principal {
          Service = "kinesis.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "example" {
  name   = var.policy_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Allow Kinesis to use the stream"
        Effect    = "Allow"
        Action    = ["kinesis:PutRecord", "kinesis:GetShardIterator"]
        Resource  = aws_kinesis_stream.example.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}