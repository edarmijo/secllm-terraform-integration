resource "aws_s3_bucket" "example-bucket" {
  bucket = "example-bucket"
  object_lock_enabled = true

  object_lock_configuration {
    object_lock_governance_mode = "GOVERNANCE"
    object_lock_ retention {
      mode = "GOVERNANCE"
      days = 90
    }
  }
}