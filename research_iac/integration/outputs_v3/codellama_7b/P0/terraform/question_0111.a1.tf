resource "aws_s3_bucket" "example-bucket" {
  bucket = "example-bucket"
  object_lock_enabled = true
  lifecycle_rule {
    enabled = true
    mode    = "GOVERNANCE"
    noncurrent_version_expiration {
      days = 90
    }
  }
}