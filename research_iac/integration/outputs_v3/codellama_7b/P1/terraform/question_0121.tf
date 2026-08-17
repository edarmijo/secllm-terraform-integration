provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "bucket1" {
  bucket = "my-bucket1"
  acl    = "private"
}

resource "aws_s3_bucket" "bucket2" {
  bucket = "my-bucket2"
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_policy" "bucket1_policy" {
  bucket = aws_s3_bucket.bucket1.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowLogDelivery",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "delivery.logs.amazonaws.com"
        },
        "Action" : "s3:PutObject",
        "Resource" : "arn:aws:s3:::my-bucket1/*"
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "bucket2_policy" {
  bucket = aws_s3_bucket.bucket2.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowLogDelivery",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "delivery.logs.amazonaws.com"
        },
        "Action" : "s3:PutObject",
        "Resource" : "arn:aws:s3:::my-bucket2/*"
      }
    ]
  })
}

resource "aws_s3_bucket_logging" "bucket1_logging" {
  bucket = aws_s3_bucket.bucket1.id
  target_bucket = aws_s3_bucket.bucket2.id
  target_prefix = "my-bucket1-logs"
}