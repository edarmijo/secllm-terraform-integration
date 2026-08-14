provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "vault" {
  bucket = "my-glacier-vault"
  versioning = true

  lifecycle {
    transition {
      days = 30
      storage_class = "GLACIER"
    }
  }
}

resource "aws_iam_role" "access_vault" {
  name = "access-vault-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "access_vault_policy" {
  name = "access-vault-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "${aws_s3_bucket.vault.arn}",
        "${aws_s3_bucket.vault.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role = aws_iam_role.access_vault.name
  policy_arn = aws_iam_policy.access_vault_policy.arn
}