provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "public_bucket" {
  bucket = "public-bucket"
  acl    = "public-read"

  logging {
    target_bucket = aws_s3_bucket.log_bucket.bucket
    target_prefix = "logs/"
  }
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "log-bucket"
  acl    = "log-delivery-write"
}