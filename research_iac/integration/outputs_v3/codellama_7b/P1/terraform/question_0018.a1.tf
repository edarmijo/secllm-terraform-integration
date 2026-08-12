resource "aws_iam_role_policy" "webapp_policy" {
  name        = "WebAppPolicy"
  role        = aws_iam_role.webapp_role.name
  description = "IAM policy for web application access"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::my-webapp-bucket/*"
    },
    {
      "Action": [
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:::my-webapp-table/*"
    }
  ]
}
EOF
}