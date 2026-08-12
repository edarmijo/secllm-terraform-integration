provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "example" {
  bucket = "${var.bucket_prefix}-${uuid()}"
  acl    = "public-read"

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

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.example.id
  acl    = "public-read"
}

data "aws_secretsmanager_secret" "s3_policy_secret" {
  name = var.s3_policy_secret_name
}

data "aws_secretsmanager_secret_version" "s3_policy_secret_version" {
  secret_id = data.aws_secretsmanager_secret.s3_policy_secret.id
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
          StringLike = {
            "aws:Referer" : ["${data.aws_caller_identity.current.account_id}.amazonaws.com"]
          }
        }
      }
    ]
  })
}