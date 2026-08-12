resource "aws_iam_group" "example" {
  name = "example-group"
}

resource "aws_iam_group_policy_attachment" "example" {
  group      = aws_iam_group.example.name
  policy_arn = "arn:aws:iam::123456789012:policy/example-policy"
}