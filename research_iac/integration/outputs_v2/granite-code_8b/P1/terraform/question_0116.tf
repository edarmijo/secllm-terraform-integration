# Create an S3 bucket
resource "aws_s3_bucket" "example" {
  bucket = "my_unique_bucket_name"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Create an ACL for the bucket
resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.example.id
  acl    = "private"

  access_control_policy {
    version     = "2012-10-17"
    id          = "${var.name}-acl"
    statement {
      actions   = ["s3:GetObject"]
      resources = ["arn:aws:s3:::${var.name}/*"]

      condition {
        key    = "aws:Referrer"
        values = ["https://example.com"]
      }
    }
  }
}