resource "aws_kinesis_firehose_delivery_stream" "example" {
  name        = "example-firehose-delivery-stream"
  destination = "s3"

  extended_s3_destination_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
    bucket_arn         = aws_s3_bucket.example.arn
    buffering_interval = 60
    buffering_size     = 10
    compression_format = "GZIP"
    dynamic_partitioning {
      enabled = true
    }
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = "example-firehose-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"
}