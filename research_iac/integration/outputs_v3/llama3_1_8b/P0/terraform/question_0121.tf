provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "bucket1" {
  bucket = "my-bucket-1"
  acl    = "private"

  versioning {
    enabled = true
  }

  logging {
    target_bucket = aws_s3_bucket.bucket2.id
    target_prefix = "log-prefix-1/"
  }
}

resource "aws_s3_bucket" "bucket2" {
  bucket = "my-bucket-2"
  acl    = "log-delivery-write"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_acl" "bucket1_acl" {
  bucket = aws_s3_bucket.bucket1.id
  acl    = "private"
}

resource "aws_s3_bucket_acl" "bucket2_acl" {
  bucket = aws_s3_bucket.bucket2.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_policy" "bucket1_policy" {
  bucket = aws_s3_bucket.bucket1.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = "${aws_s3_bucket.bucket1.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "bucket2_policy" {
  bucket = aws_s3_bucket.bucket2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = "${aws_s3_bucket.bucket2.arn}/*"
      }
    ]
  })
}