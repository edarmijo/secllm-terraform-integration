provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_group" "example" {
  name = "basic-group"
}

resource "aws_iam_user" "example1" {
  name     = "user1"
  group    = aws_iam_group.example.name
  password = var.password
}

resource "aws_iam_user" "example2" {
  name     = "user2"
  group    = aws_iam_group.example.name
  password = var.password
}