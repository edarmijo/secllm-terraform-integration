provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "s3_bucket_role" {
  name        = "s3-bucket-role"
  description = "Role for s3 bucket"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "s3_bucket_policy" {
  name        = "s3-bucket-policy"
  description = "Policy for s3 bucket"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.example.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_bucket_attach" {
  role       = aws_iam_role.s3_bucket_role.name
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
}

resource "aws_s3_bucket" "example" {
  bucket = "my-tf-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }
}