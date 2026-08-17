provider "aws" {
  region = "us-west-2"
}

# Define AWS Secrets Manager secret for S3 bucket access
data "aws_secretsmanager_secret" "s3_access" {
  name = "s3-access-credentials"
}

data "aws_secretsmanager_secret_version" "s3_access" {
  secret_id = data.aws_secretsmanager_secret.s3_access.id
}

locals {
  s3_access_credentials = jsondecode(data.aws_secretsmanager_secret_version.s3_access.secret_string)
}

# Create S3 buckets
resource "aws_s3_bucket" "bucket1" {
  bucket = "my-private-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket" "bucket2" {
  bucket = "my-log-bucket"
  acl    = "log-delivery-write"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Configure S3 bucket logging
resource "aws_s3_bucket_logging" "bucket1_logging" {
  bucket = aws_s3_bucket.bucket1.id

  target_bucket = aws_s3_bucket.bucket2.id
  target_prefix = "logs/my-private-bucket/"
}

# Define IAM role for S3 access
resource "aws_iam_role" "s3_access_role" {
  name        = "s3-access-role"
  description = "Role for accessing S3 buckets"

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

resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3-access-policy"
  description = "Policy for accessing S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.bucket1.arn,
          aws_s3_bucket.bucket2.arn,
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_attach" {
  role       = aws_iam_role.s3_access_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}