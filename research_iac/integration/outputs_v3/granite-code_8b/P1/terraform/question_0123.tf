resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name

  # Ownership controls
  ownership_controls {
    rule {
      object_ownership = "BucketOwnerPreferred"
    }
  }
}