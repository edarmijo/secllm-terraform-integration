provider "aws" {
  region = "us-east-1"
}

resource "aws_kinesis_firehose_delivery_stream" "firehose_stream" {
  name = "firehose-stream"

  destination_configuration {
    type = "extended_s3"

    extended_s3_destination {
      bucket_arn = "arn:aws:s3:::my-bucket"

      dynamic "partition_key" {
        for_each = var.partition_keys

        content {
          field_name = partition_key.value
        }
      }

      buffering_hints {
        size_in_mb = 4
        interval_in_seconds = 60
      }

      cloudwatch_logging_options {
        enabled = true
        log_group_name = "/aws/kinesisfirehose/firehose-stream"
        log_stream_name = "firehose-stream-logs"
      }
    }
  }
}