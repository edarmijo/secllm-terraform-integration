provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example" {
  bucket        = "example-bucket"
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expire-objects"
    prefix  = ""
    enabled = true

    expiration {
      days = 30
    }
  }
}