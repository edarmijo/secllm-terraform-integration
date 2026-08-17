provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example-bucket" {
  bucket = "example-bucket"
  object_lock_configuration {
    rule {
      default_retention {
        days = 90
        mode = "GOVERNANCE"
      }
    }
  }
}