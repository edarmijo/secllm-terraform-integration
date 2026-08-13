provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_group" "example_group" {
  name = "example_group"
}

resource "aws_iam_policy" "example_policy" {
  name = "example_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_group_policy_attachment" "example_attachment" {
  group = aws_iam_group.example_group.name
  policy_arn = aws_iam_policy.example_policy.arn
}