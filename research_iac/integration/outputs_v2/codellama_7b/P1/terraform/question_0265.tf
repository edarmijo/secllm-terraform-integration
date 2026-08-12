provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_user" "example" {
  name          = "example"
  path          = "/"
  force_destroy = true
}

resource "aws_iam_access_key" "example" {
  user    = aws_iam_user.example.name
  pgp_key = "keybase:username"
}