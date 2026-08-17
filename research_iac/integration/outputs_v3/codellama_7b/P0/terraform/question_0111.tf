resource "aws_s3_bucket" "example-bucket" {
  bucket = "example-bucket"
  object_lock_enabled = true
  object_lock_governance_mode = "GOVERNANCE"
  object_lock_retention_period = 90
}