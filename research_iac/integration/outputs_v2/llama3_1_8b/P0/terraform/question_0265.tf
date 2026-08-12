provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_user" "example" {
  name          = "example-user"
  force_destroy = true
}

resource "aws_iam_access_key" "example" {
  user        = aws_iam_user.example.name
  status      = "Active"
}

resource "aws_iam_user_policy_attachment" "example" {
  user       = aws_iam_user.example.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}