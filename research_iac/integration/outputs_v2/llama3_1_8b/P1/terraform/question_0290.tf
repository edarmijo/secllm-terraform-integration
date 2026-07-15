provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret_version" "s3_bucket_access_key_id" {
  secret_id = var.s3_bucket_access_key_id_secret_id
}

data "aws_secretsmanager_secret_version" "s3_bucket_secret_access_key" {
  secret_id = var.s3_bucket_secret_access_key_secret_id
}

resource "aws_iam_role" "s3_bucket_role" {
  name        = "S3BucketRole"
  description = "IAM role for S3 bucket"

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

resource "aws_iam_policy" "s3_bucket_policy" {
  name        = "S3BucketPolicy"
  description = "IAM policy for S3 bucket"

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
        Effect   = "Allow"
        Resource = aws_s3_bucket.s3_bucket.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_bucket_attach" {
  role       = aws_iam_role.s3_bucket_role.name
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.s3_bucket_name

  versioning {
    enabled = true
  }

  acl   = "private"
  tags = {
    Name        = var.s3_bucket_name
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "s3_bucket_versioning" {
  bucket = aws_s3_bucket.s3_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}