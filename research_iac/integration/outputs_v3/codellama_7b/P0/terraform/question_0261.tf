provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_user" "user1" {
  name = "user1"
}

resource "aws_iam_user" "user2" {
  name = "user2"
}

resource "aws_iam_group" "basic_group" {
  name = "basic_group"
}

resource "aws_iam_group_membership" "basic_group_memberships" {
  group = aws_iam_group.basic_group.name
  users = [aws_iam_user.user1.name, aws_iam_user.user2.name]
}