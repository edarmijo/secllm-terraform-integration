provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "private_bucket" {
  bucket = "private-bucket"
  acl    = "private"
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "log-bucket"
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_logging" "log_bucket_logging" {
  bucket = aws_s3_bucket.log_bucket.id

  target_bucket = aws_s3_bucket.private_bucket.id
  target_prefix = "logs/"
}