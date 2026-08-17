provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "first_bucket" {
  bucket = "first-bucket"
}

resource "aws_s3_bucket" "second_bucket" {
  bucket = "second-bucket"
}

resource "aws_s3_bucket_logging" "example_logging" {
  bucket = aws_s3_bucket.first_bucket.bucket
  target_bucket = aws_s3_bucket.second_bucket.bucket
  prefix = "log/"
}