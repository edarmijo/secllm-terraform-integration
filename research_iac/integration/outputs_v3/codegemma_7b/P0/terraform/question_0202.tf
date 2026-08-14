provider "aws" {
  region = "us-east2"
}

resource "aws_msk_cluster" "example" {
  name                = "example-cluster"
  broker_node_group_info {
    instance_type = "kafka.m5.large"
    desired_nodes = 3
  }
  kafka_version = "2.8.1"
  logging {
    broker {
      enabled = true
    }
  }
}