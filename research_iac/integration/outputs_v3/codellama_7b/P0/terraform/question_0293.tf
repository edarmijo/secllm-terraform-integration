provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example" {
  bucket        = "my-tf-test-bucket"
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket" "logs" {
  bucket        = "my-tf-test-logs-bucket"
  acl           = "log-delivery-write"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.example.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:PutObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.example.arn}/*"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:PutObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.logs.arn}/*"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
      },
    ]
  })
}