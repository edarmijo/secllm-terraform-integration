provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "access_logs_bucket" {
  bucket = "access-logs-bucket"
}

resource "aws_s3_bucket" "server_logs_bucket" {
  bucket = "server-logs-bucket"
}

resource "aws_s3_bucket_logging" "server_logs_bucket_logging" {
  bucket = aws_s3_bucket.server_logs_bucket.id
  target_bucket = aws_s3_bucket.access_logs_bucket.id
  target_prefix = "server-logs/"
}