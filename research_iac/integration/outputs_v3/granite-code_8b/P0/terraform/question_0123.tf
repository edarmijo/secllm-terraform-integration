resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name

  // Configure ownership controls for the S3 bucket
  ownership_controls {
    rule {
      object_ownership = "BucketOwnerPreferred"
    }
  }
}