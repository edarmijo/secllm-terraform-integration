resource "aws_iam_group" "example" {
  name = "example-group"
}

resource "aws_iam_group_membership" "example" {
  name = "example-group-membership"

  group = aws_iam_group.example.name

  users = [
    aws_iam_user.example1.name,
    aws_iam_user.example2.name,
  ]
}