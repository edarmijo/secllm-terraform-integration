provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret" "example_secret" {
  name = "example-secret"
}

resource "aws_iam_user" "example_user" {
  name        = "example-user"
  force_destroy = true

  tags = {
    Name = "Example User"
  }
}

resource "aws_iam_access_key" "example_key" {
  user = aws_iam_user.example_user.name
}

resource "aws_iam_user_policy" "example_policy" {
  name        = "example-policy"
  user        = aws_iam_user.example_user.name

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowProgrammaticAccess"
        Effect    = "Allow"
        Action    = ["sts:AssumeRole"]
        Resource  = "*"
      },
      {
        Sid       = "ReadOnlyAccess"
        Effect    = "Allow"
        Action    = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
        ]
        Resource  = [
          "arn:aws:s3:::example-bucket",
          "arn:aws:s3:::example-bucket/*",
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "example_attach" {
  name       = "example-attach"
  user       = aws_iam_user.example_user.name
  policy_arn = aws_iam_user_policy.example_policy.arn
}