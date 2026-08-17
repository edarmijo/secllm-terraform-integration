provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "bucket1" {
  bucket = "bucket1"
}

resource "aws_s3_bucket" "bucket2" {
  bucket = "bucket2"
}

resource "aws_s3_bucket_logging" "logging" {
  bucket = aws_s3_bucket.bucket1.bucket
  target_bucket = aws_s3_bucket.bucket2.bucket
  target_prefix = "log/"
}