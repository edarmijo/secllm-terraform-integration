resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  payment_preference = "RequesterPays"
}