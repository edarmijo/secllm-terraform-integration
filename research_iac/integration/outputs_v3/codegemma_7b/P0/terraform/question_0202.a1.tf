provider "aws" {
  region = "us-east2"
}

resource "aws_msk_cluster" "example" {
  cluster_name = "example-cluster"
  number_of_broker_nodes = 3
  broker_node_group_info {
    instance_type = "kafka.m5.large"
  }
  kafka_version = "2.8.1"
  logging {
    broker {
      enabled = true
    }
  }
}