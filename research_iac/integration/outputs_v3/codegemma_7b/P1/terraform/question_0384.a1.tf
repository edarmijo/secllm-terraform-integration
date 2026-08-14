resource "aws_s3_bucket" "vault" {
  bucket = "my-vault"
  versioning = true

  acl = "private"

  lifecycle {
    transition_to_storage_class {
      days = 30
      storage_class = "GLACIER"
    }
  }
}