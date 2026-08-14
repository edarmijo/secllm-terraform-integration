provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "example" {
  bucket = "mybucket"
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

resource "aws_s3_bucket_metric" "example" {
  bucket_name = aws_s3_bucket.example.id

  name_prefix = "MyBucketMetric"

  namespace = "AWS/S3"

  dimensions {
    StorageClass = "STANDARD"
  }

  dimensions {
    StorageType = "Standard-IA"
  }
}

resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.example.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = "${aws_s3_bucket.example.arn}/*"

        Condition = {
          Bool = {
            "aws:CurrentAccount" : "123456789012"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role" "example" {
  name        = "mybucket-execution-role"
  description = "Execution role for my S3 bucket"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "example" {
  name   = "mybucket-execution-policy"
  role   = aws_iam_role.example.id

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
        Resource = "${aws_s3_bucket.example.arn}/*"
      },
    ]
  })
}