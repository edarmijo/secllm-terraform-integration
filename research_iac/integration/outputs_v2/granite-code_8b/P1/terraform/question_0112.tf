resource "aws_s3_bucket" "example-bucket" {
  bucket = "example-bucket"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  object_lock_enabled = true
  object_lock_legal_hold_enabled = false
  object_lock_ retention {
    mode  = "GOVERNANCE"
    days  = 30
  }
}