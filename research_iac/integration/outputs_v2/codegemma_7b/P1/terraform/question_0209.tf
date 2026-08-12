provider "aws" {
  region = "us-east-1"
}

resource "aws_msk_cluster" "example" {
  name = "example-cluster"

  broker_node_group_info {
    desired_instance_count = 3
    instance_type = "kafka.t3.medium"
  }

  kafka_version = "2.8.1"

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.example.arn
    encryption_in_transit_tls_enabled = true
  }

  logging_info {
    broker_logs {
      enabled = true
      destination = aws_s3_bucket.example.bucket
    }
  }
}

resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"
}

resource "aws_kms_key" "example" {
  description = "Example KMS key for MSK encryption"
  key_usage = "ENCRYPT_DECRYPT"
}