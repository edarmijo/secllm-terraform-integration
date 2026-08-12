provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "s3_bucket_role" {
  name        = "S3BucketOwnerPaysRole"
  description = "Allows S3 bucket owner to pay for fees"

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

resource "aws_iam_policy" "s3_bucket_policy" {
  name        = "S3BucketOwnerPaysPolicy"
  description = "Allows S3 bucket owner to pay for fees"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = aws_s3_bucket.s3_bucket.arn
      },
      {
        Action = "s3:PutObjectAcl"
        Effect = "Allow"
        Resource = "${aws_s3_bucket.s3_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy_to_role" {
  role       = aws_iam_role.s3_bucket_role.name
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket        = "my-s3-bucket-owner-pays"
  acl           = "private"

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

  lifecycle_rule {
    enabled = true

    expiration {
      days = 30
    }
  }
}