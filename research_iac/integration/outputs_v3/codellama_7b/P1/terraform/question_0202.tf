provider "aws" {
  region = "us-east-2"
}

resource "aws_msk_cluster" "example" {
  name                   = "example-msk-cluster"
  number_of_broker_nodes = 3
  broker_node_group_info {
    instance_type  = "kafka.m5.large"
    ebs_volume_size = 100
  }
}