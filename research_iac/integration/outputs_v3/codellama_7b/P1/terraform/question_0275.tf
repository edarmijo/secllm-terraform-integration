provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "mybucket" {
  bucket = "mybucket"
}

resource "aws_s3_bucket_metric" "mybucket" {
  bucket = aws_s3_bucket.mybucket.id
  name   = "EntireBucket"
}