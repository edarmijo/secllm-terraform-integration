provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_bucket_access" "example" {
  bucket_name = "my-bucket"
  user_name    = "lightsail-user"
  access_role  = aws_iam_role.lightsail-role.arn
}

resource "aws_iam_role" "lightsail-role" {
  name = "lightsail-role"

  assume_role_policy = <<POLICY
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
    POLICY

  policy {
    policy_document = <<POLICY
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "s3:GetObject",
            "s3:ListBucket"
          ],
          "Resource": [
            "arn:aws:s3:::my-bucket",
            "arn:aws:s3:::my-bucket/*"
          ]
        }
      ]
    }
    POLICY
  }
}