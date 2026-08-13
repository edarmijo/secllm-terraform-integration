provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_bucket" "example" {
  name        = "my-bucket"
  access_type = "private"
}

resource "aws_iam_role" "example" {
  name               = "example-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lightsail.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "example" {
  name   = "example-policy"
  role   = aws_iam_role.example.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect   = "Allow"
        Resource = aws_lightsail_bucket.example.arn
      },
    ]
  })
}