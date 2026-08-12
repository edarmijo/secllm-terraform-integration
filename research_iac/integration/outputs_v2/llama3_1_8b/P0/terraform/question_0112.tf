provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "s3_bucket_policy_execution" {
  name        = "example-bucket-execution-role"
  description = "Execution role for S3 bucket policy"

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
  description = "Policy for S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3BucketAccess"
        Effect    = "Allow"
        Action    = ["s3:GetObject", "s3:PutObject"]
        Resource = aws_s3_bucket.example-bucket.arn
      },
      {
        Sid       = "EnableObjectLock"
        Effect    = "Allow"
        Action    = ["s3:PutBucketLifecycleConfiguration"]
        Resource = aws_s3_bucket.example-bucket.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy_to_execution_role" {
  role       = aws_iam_role.s3_bucket_policy_execution.name
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
}

resource "aws_s3_bucket" "example-bucket" {
  bucket = "example-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  object_lock_configuration {
    object_lock_enabled = true

    rule {
      default_retention_days = 30
    }
  }
}