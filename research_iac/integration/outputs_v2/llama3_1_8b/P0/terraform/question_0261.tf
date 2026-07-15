provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_group" "example_group" {
  name = "example-group"
}

resource "aws_iam_user" "user1" {
  name          = "user1"
  group         = aws_iam_group.example_group.name
  force_destroy = true
}

resource "aws_iam_user" "user2" {
  name          = "user2"
  group         = aws_iam_group.example_group.name
  force_destroy = true
}