provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"
  acl    = "private"
}

resource "aws_s3_bucket" "example_logs" {
  bucket = "example-logs-bucket"
  acl    = "private"
}

resource "aws_s3_bucket_logging" "example" {
  bucket        = aws_s3_bucket.example.id
  target_bucket = aws_s3_bucket.example_logs.id
  prefix        = "log/"
}