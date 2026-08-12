provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_bucket_access" "example" {
  bucket_name = "my-bucket"
  user_name    = "lightsail-user"
  access_role  = "arn:aws:iam::123456789012:role/lightsail-role"
}

resource "aws_iam_role" "lightsail-role" {
  name = "lightsail-role"

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