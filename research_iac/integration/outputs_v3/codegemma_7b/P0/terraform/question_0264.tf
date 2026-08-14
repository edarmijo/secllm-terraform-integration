provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_group" "example_group" {
  name = "example_group"
}

resource "aws_iam_role" "example_role" {
  name = "example_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_group_membership" "example_membership" {
  group = aws_iam_group.example_group.name
  users = ["user1", "user2"]
}

resource "aws_iam_role_policy_attachment" "example_policy" {
  role       = aws_iam_role.example_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}