provider "aws" {
  region = "us-east1"
}

resource "aws_msk_cluster" "example" {
  name                = "example-cluster"
  kafka_version       = "2.8.1"
  broker_node_group_info {
    instance_type = "kafka.t3.medium"
    desired_instance_count = 2
  }
  logging {
    cluster_logs {
      enabled = true
      log_group_name = aws_cloudwatch_log_group.example.name
    }
  }
}

resource "aws_cloudwatch_log_group" "example" {
  name = "/example-cluster-logs"
}