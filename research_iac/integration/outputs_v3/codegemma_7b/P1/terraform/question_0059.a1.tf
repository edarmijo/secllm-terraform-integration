provider "aws" {
  region = "us-east-1"
}

resource "aws_kinesis_firehose_delivery_stream" "firehose_stream" {
  name = "firehose-stream"

  destination {
    type = "s3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.s3_bucket.arn
      role_arn = aws_iam_role.firehose_role.arn

      dynamic "partitioner" {
        for_each = var.partition_keys

        content {
          field_name = partitioner.value
        }
      }
    }
  }

  buffering_interval = 60
  buffering_size = 1024000
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "firehose-bucket"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}