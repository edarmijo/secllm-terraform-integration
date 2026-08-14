provider "aws" {
  region = "us-east-1"
}

resource "aws_kinesis_firehose_delivery_stream" "firehose_stream" {
  name = "firehose-stream"

  destination_id = aws_s3_bucket.s3_bucket.arn

  dynamic "partitioner" {
    for_each = var.partition_keys

    content {
      field_name = partitioner.value
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