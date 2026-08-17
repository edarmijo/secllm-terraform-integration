provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "bucket1" {
  bucket = "my-bucket1"
}

resource "aws_s3_bucket" "bucket2" {
  bucket = "my-bucket2"
}

resource "aws_s3_bucket_logging" "bucket1_logging" {
  bucket = aws_s3_bucket.bucket1.id
  target_bucket = aws_s3_bucket.bucket2.id
  target_prefix = "log/"
}