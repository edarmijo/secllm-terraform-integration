provider "aws" {
  region = "us-east-1"
}

resource "aws_msk_cluster" "example" {
  name                   = "example-msk-cluster"
  number_of_broker_nodes = 3
  broker_node_group_info {
    instance_type  = "kafka.m5.large"
    ebs_volume_size = 100
  }
  logging_info {
    cloudwatch_logs {
      enabled   = true
      log_group = aws_cloudwatch_log_group.example.name
    }
  }
}

resource "aws_cloudwatch_log_group" "example" {
  name = "example-msk-cluster-logs"
}