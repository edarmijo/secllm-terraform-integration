provider "aws" {
  region = "us-east-1"
}

resource "aws_kinesis_analytics_application" "kinesis_app" {
  name = "my-kinesis-app"

  inputs {
    name = "cloudwatch-log-input"
    kinesis_stream = aws_kinesis_stream.cloudwatch_log_stream.name
    schema = file("input_schema.json")
  }

  outputs {
    name = "firehose-output"
    firehose_destination {
      arn = aws_firehose_delivery_stream.firehose_stream.arn
    }
  }
}

resource "aws_kinesis_stream" "cloudwatch_log_stream" {
  name = "my-cloudwatch-log-stream"
  retention_period = 7 * 24 * 60 * 60
}

resource "aws_firehose_delivery_stream" "firehose_stream" {
  name = "my-firehose-stream"
  destination_type = "S3"
  s3_destination {
    bucket = aws_s3_bucket.firehose_bucket.bucket
    prefix = "firehose-output"
  }
}

resource "aws_s3_bucket" "firehose_bucket" {
  bucket = "my-firehose-bucket"
}