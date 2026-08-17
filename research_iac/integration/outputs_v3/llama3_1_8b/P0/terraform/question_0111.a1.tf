provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "s3_bucket_role" {
  name        = "example-bucket-role"
  description = "Role for example-bucket"

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
  name        = "example-bucket-policy"
  description = "Policy for example-bucket"

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
        Resource = "arn:aws:s3:::example-bucket/*"
      },
      {
        Action = [
          "s3:PutObjectRetention",
        ]
        Effect = "Allow"
        Resource = "arn:aws:s3:::example-bucket/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_bucket_attach" {
  role       = aws_iam_role.s3_bucket_role.name
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
}

resource "aws_s3_bucket" "example_bucket" {
  bucket = "example-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  object_lock_configuration {
    object_lock_enabled = "Enabled"
    rule {
      default_retention {
        mode = "GOVERNANCE"
        days = 90
      }
    }
  }
}