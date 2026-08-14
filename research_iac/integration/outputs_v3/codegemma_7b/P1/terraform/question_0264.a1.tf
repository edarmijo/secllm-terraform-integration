resource "aws_iam_group_membership" "example_membership" {
  group = aws_iam_group.example_group.name
  users = ["user1", "user2"]
  name = "example_membership" # Add this line
}