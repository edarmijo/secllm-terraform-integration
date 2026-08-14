provider "aws" {
  region = var.region
}

variable "server_access_logs_bucket_name" {
  type        = string
  description = "Name of the server access logs bucket"
}

resource "aws_s3_bucket" "server_access_logs" {
  bucket = var.server_access_logs_bucket_name
  acl    = "log-delivery-write"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

variable "access_logs_bucket_name" {
  type        = string
  description = "Name of the access logs bucket"
}

resource "aws_s3_bucket" "access_logs" {
  bucket = var.access_logs_bucket_name

  logging {
    target_bucket = aws_s3_bucket.server_access_logs.id
    target_prefix = "logs/"
  }
}