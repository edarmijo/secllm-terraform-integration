provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example-bucket" {
  bucket        = "example-bucket"
  acl           = "private"
  object_lock_enabled = true
  object_lock_mode = "GOVERNANCE"
  object_lock_retain_until_date = "2023-01-01T00:00:00Z"
}