resource "aws_s3_vault" "example" {
  name = "example-vault"
}

resource "aws_iam_policy" "example" {
  name        = "example-policy"
  description = "Policy for accessing the S3 Glacier vault"

  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "${aws_s3_vault.example.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "${aws_s3_vault.example.arn}/*"
    }
  ]
}
EOF
}