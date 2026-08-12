provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_bucket_access" "example" {
  bucket_name = "my-bucket"
  access_role_name = "lightsail-bucket-access"

  resource_access {
    type = "bucket"
    bucket_name = "my-bucket"
  }
}

resource "aws_iam_role" "lightsail-bucket-access" {
  name = "lightsail-bucket-access"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lightsail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lightsail-bucket-access-policy" {
  name = "lightsail-bucket-access-policy"
  role = aws_iam_role.lightsail-bucket-access.name

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
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-bucket/*"
      ]
    }
  ]
}
EOF
}