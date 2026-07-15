provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_group" "example_group" {
  name = "ExampleGroup"
}

resource "aws_iam_policy" "example_policy" {
  name        = "ExamplePolicy"
  description = "An example policy"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:GetObject"]
        Effect = "Allow"
        Resource = ["arn:aws:s3:::example-bucket/*"]
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "example_attachement" {
  name       = "ExampleAttachment"
  group      = aws_iam_group.example_group.name
  policy_arn = aws_iam_policy.example_policy.arn
}