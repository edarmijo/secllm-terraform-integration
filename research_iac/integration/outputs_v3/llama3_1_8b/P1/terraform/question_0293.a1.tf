provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket to create."
}

variable "log_bucket_name" {
  type        = string
  description = "The name of the S3 bucket for server access logs."
}

resource "aws_s3_bucket" "example" {
  bucket        = var.bucket_name
  acl           = "private"
  force_destroy = true

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

resource "aws_s3_bucket" "logs" {
  bucket        = var.log_bucket_name
  acl           = "private"
  force_destroy = true

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

resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.example.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSSE-KMS"
        Effect    = "Allow"
        Action    = ["kms:GenerateDataKey*", "kms:Decrypt"]
        Resource  = "*"
        Condition  = {
          StringEquals = {
            "kms:EncryptionContext:aws:s3:::${var.bucket_name}" = true
          }
        }
      },
      {
        Sid       = "AllowSSE-KMS-Logs"
        Effect    = "Allow"
        Action    = ["kms:GenerateDataKey*", "kms:Decrypt"]
        Resource  = "*"
        Condition  = {
          StringEquals = {
            "kms:EncryptionContext:aws:s3:::${var.log_bucket_name}" = true
          }
        }
      },
      {
        Sid       = "AllowServerAccessLogs"
        Effect    = "Allow"
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.logs.arn}/*"
      },
      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Action    = "s3:PutObject"
        Resource  = aws_s3_bucket.example.arn
        Condition  = {
          StringNotEquals = {
            "aws:s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      },
      {
        Sid       = "DenyUnencryptedObjectUploads-Logs"
        Effect    = "Deny"
        Action    = "s3:PutObject"
        Resource  = aws_s3_bucket.logs.arn
        Condition  = {
            StringNotEquals = {
              "aws:s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}