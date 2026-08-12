provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example" {
  bucket = "my_unique_bucket_name"
  acl    = "private"
}

resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.example.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.example.arn}/*"
        Condition = {
          StringEquals = {
            Referer = var.allowed_referers
          }
        }
      },
    ]
  })
}