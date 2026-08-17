provider "aws" {
  region = "us-west-2"
}

data "aws_secretsmanager_secret" "s3_bucket_secret" {
  name = "s3-bucket-secret"
}

data "aws_secretsmanager_secret_version" "s3_bucket_secret_version" {
  secret_id = data.aws_secretsmanager_secret.s3_bucket_secret.id
}

resource "aws_iam_role" "s3_bucket_role" {
  name        = "s3-bucket-role"
  description = "Role for S3 bucket access"

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
  name        = "s3-bucket-policy"
  description = "Policy for S3 bucket access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl",
          "s3:PutBucketAcl",
          "s3:GetBucketAcl",
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.example-bucket.arn,
          "${aws_s3_bucket.example-bucket.arn}/*",
        ]
      },
      {
        Action = "s3:PutObject"
        Effect = "Allow"
        Resource = aws_s3_bucket.example-bucket.arn
        Condition = {
          StringEquals = {
            "s3:x-amz-bucket-owner" = "example-bucket-owner"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_bucket_attach" {
  role       = aws_iam_role.s3_bucket_role.name
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
      default_retention {
        mode = "GOVERNANCE"
        days = 90
      }
    }
  }
}