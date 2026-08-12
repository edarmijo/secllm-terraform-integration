provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example-bucket" {
  bucket        = "example-bucket"
  acl           = "private"
  versioning    = {
    enabled = true
  }
  object_lock_configuration {
    mode = "GOVERNANCE"
    retention_period = 30
  }
}