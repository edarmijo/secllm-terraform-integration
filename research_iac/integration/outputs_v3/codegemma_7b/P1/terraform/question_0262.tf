# Create an IAM group
resource "aws_iam_group" "example_group" {
  name = "example_group"
}

# Create an IAM policy
resource "aws_iam_policy" "example_policy" {
  name = "example_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::my-bucket/*"]
    }
  ]
}
EOF
}

# Attach the policy to the group
resource "aws_iam_group_policy_attachment" "example_attachment" {
  group = aws_iam_group.example_group.name
  policy_arn = aws_iam_policy.example_policy.arn
}