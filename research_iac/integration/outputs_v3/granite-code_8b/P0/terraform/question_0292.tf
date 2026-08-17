provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example_bucket" {
  bucket = "example-bucket"
}

resource "aws_s3_bucket" "example_log_bucket" {
  bucket = "example-log-bucket"
}

resource "aws_s3_bucket_logging" "example_logging" {
  bucket = aws_s3_bucket.example_bucket.id
  target_bucket = aws_s3_bucket.example_log_bucket.id
  target_prefix = "log/"
}