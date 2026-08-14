provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_vault" "example" {
  name        = "example-glacier-vault"
  access_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::example-glacier-vault/*"
    }
  ]
}
EOF
}