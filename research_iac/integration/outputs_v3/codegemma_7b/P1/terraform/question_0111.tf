provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example-bucket" {
  bucket = "example-bucket"

  versioning {
    enabled = true
  }

  object_lock {
    enabled = true

    rule {
      default_Retention {
        days = 90
      }
    }
  }
}