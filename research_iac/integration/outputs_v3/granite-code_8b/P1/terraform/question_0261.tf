resource "aws_iam_group" "example" {
  name = "example-group"
}

resource "aws_iam_user" "user1" {
  name = "user1"
}

resource "aws_iam_user" "user2" {
  name = "user2"
}

resource "aws_iam_group_membership" "example" {
  group  = aws_iam_group.example.name
  user   = aws_iam_user.user1.name
}

resource "aws_iam_group_membership" "example" {
  group  = aws_iam_group.example.name
  user   = aws_iam_user.user2.name
}