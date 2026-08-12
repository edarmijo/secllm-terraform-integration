provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret" "s3_bucket_access_key_id" {
  name = "S3BucketAccessKeyId"
}

data "aws_secretsmanager_secret" "s3_bucket_secret_access_key" {
  name = "S3BucketSecretAccessKey"
}

resource "aws_iam_role" "example-bucket-role" {
  name        = "example-bucket-execution-role"
  description = "Execution role for example-bucket"

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
    ]
  })
}

resource "aws_iam_policy" "example-bucket-policy" {
  name   = "example-bucket-execution-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucketMultipartUploads",
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.example-bucket.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example-bucket-attachment" {
  role       = aws_iam_role.example-bucket-role.name
  policy_arn = aws_iam_policy.example-bucket-policy.arn
}

resource "aws_s3_bucket" "example-bucket" {
  bucket        = "example-bucket"
  acl           = "private"

  versioning {
    enabled = true
  }

  object_lock_configuration {
    object_lock_enabled = true

    rule {
      default_retention_days = 30
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "example-bucket-policy" {
  bucket = aws_s3_bucket.example-bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = "${aws_s3_bucket.example-bucket.arn}/*"

        Condition = {
          NotIpAddress = {
            aws_s3_bucket.example-bucket.id,
            "0.0.0.0/0",
          }
        }
      },
    ]
  })
}