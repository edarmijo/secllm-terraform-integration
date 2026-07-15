provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_group" "example" {
  name = "example-group"
}

resource "aws_iam_group_policy_attachment" "example" {
  group      = aws_iam_group.example.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}