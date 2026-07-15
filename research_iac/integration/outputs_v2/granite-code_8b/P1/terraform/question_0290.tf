resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"

  versioning {
    enabled    = true
    mfa_delete = false
  }
}