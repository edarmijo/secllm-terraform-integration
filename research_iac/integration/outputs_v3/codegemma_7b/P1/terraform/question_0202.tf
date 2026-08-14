provider "aws" {
  region = "us-east-2"
}

resource "aws_msk_cluster" "example" {
  name                = "my-msk-cluster"
  kafka_version       = "2.8.1"
  broker_node_group_info {
    instance_type = "kafka.t3.medium"
    desired_nodes = 3
  }
  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.example.arn
    encryption_in_transit_enabled = true
  }
}

resource "aws_kms_key" "example" {
  description = "MSK encryption key"
  enable_key_rotation = true
}