provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example" {
  bucket = "my_unique_bucket_name"
  acl    = "private"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:GetObject"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::example/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:Referrer": "*"
                }
            },
            "Principal": "*"
        }
    ]
}
EOF
}