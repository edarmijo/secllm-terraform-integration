provider "aws" {
  region = "us-west-2"
}

resource "random_string" "suffix" {
  length    = 8
  special   = false
}

resource "aws_s3_bucket" "example" {
  bucket = "my_unique_bucket_name-${random_string.suffix.result}"
  acl    = "public-read"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.example.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.example.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = "${aws_s3_bucket.example.arn}/*"

        Condition = {
          StringLike = {
            "aws:Referer" : ["http://example.com/*", "https://example.com/*"]
          }
        }
      }
    ]
  })
}