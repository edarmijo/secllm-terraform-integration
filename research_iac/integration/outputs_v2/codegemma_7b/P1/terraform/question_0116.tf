provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "my_unique_bucket" {
  bucket = "my_unique_bucket_name"
  acl    = "public-read"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": [
        "${aws_s3_bucket.my_unique_bucket.arn}/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:Referer": "*"
        }
      }
    }
  ]
}
POLICY
}