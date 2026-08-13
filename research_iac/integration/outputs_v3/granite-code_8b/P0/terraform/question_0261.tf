provider "aws" {
  region = var.region
}

resource "aws_iam_group" "basic_group" {
  name = "basic-group"
}

resource "aws_iam_user" "basic_user1" {
  name = "basic-user1"
}

resource "aws_iam_user" "basic_user2" {
  name = "basic-user2"
}

resource "aws_iam_group_membership" "group_membership1" {
  user   = aws_iam_user.basic_user1.name
  group  = aws_iam_group.basic_group.name
}

resource "aws_iam_group_membership" "group_membership2" {
  user   = aws_iam_user.basic_user2.name
  group  = aws_iam_group.basic_group.name
}