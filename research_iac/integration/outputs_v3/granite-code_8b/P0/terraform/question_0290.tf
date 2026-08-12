resource "aws_s3_bucket" "example" {
  bucket = "tf-acc-test-s3-versioning-example"

  versioning {
    enabled    = true
    mfa_delete = false
  }
}