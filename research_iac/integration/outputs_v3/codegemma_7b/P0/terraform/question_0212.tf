provider "aws" {
  region = "us-east-1"
}

resource "aws_msk_cluster" "example" {
  name = "example-msk-cluster"

  broker_node_group_info {
    instance_type = "kafka.m5.large"
    num_nodes = 3
  }

  kafka_version = "2.8.1"

  encryption_info {
    encryption_at_rest_kms_key_id = aws_kms_key.example.arn
  }

  monitoring_configuration {
    log_group_name = aws_cloudwatch_log_group.example.name
  }

  configuration_info {
    external_configuration {
      location = "s3://example-bucket/config.properties"
    }
  }

  output_parameters {
    kafka_broker_logs {
      cloudwatch_logs {
        enabled = true
        log_group_name = aws_cloudwatch_log_group.example.name
      }

      s3 {
        enabled = true
        bucket = aws_s3_bucket.example.bucket
        prefix = "msk-logs"
      }

      kinesis_firehose {
        enabled = true
        delivery_stream_name = aws_kinesis_firehose_delivery_stream.example.name
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "example" {
  name = "/example-msk-logs"
}

resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"
}

resource "aws_kinesis_firehose_delivery_stream" "example" {
  name = "example-firehose-stream"

  destination {
    s3 {
      bucket_arn = aws_s3_bucket.example.arn
      prefix = "firehose-logs"
    }
  }
}

resource "aws_kms_key" "example" {
  description = "MSK encryption key"
  enable_key_rotation = true
}