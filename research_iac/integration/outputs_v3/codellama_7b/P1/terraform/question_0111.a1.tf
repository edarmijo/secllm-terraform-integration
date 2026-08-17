provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example-bucket" {
  bucket = "example-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  object_lock_enabled = true

  object_lock_configuration {
    object_lock_enabled = true
    rule {
      default_retention {
        mode = "GOVERNANCE"
        days = 90
      }
    }
  }
}