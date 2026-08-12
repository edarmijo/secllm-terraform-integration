provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_user" "example_user" {
  name = "example_user"
}

resource "aws_iam_access_key" "example_access_key" {
  user = aws_iam_user.example_user.name
}

resource "aws_iam_policy" "example_policy" {
  name = "example_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ec2:DescribeInstances"],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "example_policy_attachment" {
  user = aws_iam_user.example_user.name
  policy_arn = aws_iam_policy.example_policy.arn
}