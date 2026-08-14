provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "server_access_logs" {
  bucket = "my-server-access-logs"

  logging {
    target_bucket = aws_s3_bucket.server_access_logs.id
    target_prefix = "logs/"
  }
}