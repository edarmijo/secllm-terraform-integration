provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_user" "example" {
  name = "example"
}

resource "aws_iam_access_key" "example" {
  user = aws_iam_user.example.name
}