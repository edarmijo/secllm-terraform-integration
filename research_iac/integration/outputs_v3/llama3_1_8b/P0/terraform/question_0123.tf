provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "example-bucket" {
  bucket = "my-tf-s3-bucket"
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

resource "aws_s3_bucket_ownership_controls" "example-bucket-ownership-controls" {
  bucket = aws_s3_bucket.example-bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"

    noncurrent_version_expiration {
      days = 30
    }
  }
}