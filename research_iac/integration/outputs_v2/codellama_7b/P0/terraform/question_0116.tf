resource "aws_s3_bucket" "my_unique_bucket_name" {
  bucket = "my_unique_bucket_name"
}

resource "aws_s3_bucket_acl" "my_unique_bucket_name" {
  bucket = aws_s3_bucket.my_unique_bucket_name.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "my_unique_bucket_name" {
  bucket = aws_s3_bucket.my_unique_bucket_name.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.my_unique_bucket_name.arn}/*"
        Principal = {
          AWS = "*"
        }
        Condition = {
          StringEquals = {
            Referer = "https://example.com"
          }
        }
      },
    ]
  })
}