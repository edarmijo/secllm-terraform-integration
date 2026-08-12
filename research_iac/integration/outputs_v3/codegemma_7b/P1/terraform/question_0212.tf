provider "aws" {
  region = "us-east-1"
}

resource "aws_msk_cluster" "example" {
  name = "example-msk-cluster"

  broker_node_group_info {
    instance_type = "kafka.m5.large"
    desired_instance_count = 3
  }

  kafka_version = "2.8.1"

  encryption_at_rest {
    kms_key_id = aws_kms_key.example.key_id
  }

  open_monitoring {
    enabled = true
  }

  logging {
    cluster_logs {
      enabled = true
      log_group_name = aws_cloudwatch_log_group.example.name
    }

    broker_logs {
      enabled = true
      log_group_name = aws_cloudwatch_log_group.example.name
    }
  }

  provisioner "local-exec" {
    command = "aws firehose create-delivery-stream --delivery-stream-name example-firehose-delivery-stream --destination-s3 --s3-configuration {BucketARN = aws_s3_bucket.example.arn}"
  }
}

resource "aws_cloudwatch_log_group" "example" {
  name = "example-msk-log-group"
}

resource "aws_s3_bucket" "example" {
  bucket = "example-msk-bucket"
}

resource "aws_kms_key" "example" {
  description = "Example MSK encryption key"
  enable_key_rotation = true
}