provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_group" "basic_group" {
  name = "basic_group"
}

resource "aws_iam_user" "user1" {
  name = "user1"
  group = aws_iam_group.basic_group.name
}

resource "aws_iam_user" "user2" {
  name = "user2"
  group = aws_iam_group.basic_group.name
}