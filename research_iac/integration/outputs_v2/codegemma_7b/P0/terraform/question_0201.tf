provider "aws" {
  region = "us-east-1"
}

resource "aws_msk_cluster" "example" {
  name                = "my-msk-cluster"
  broker_node_group_info {
    desired_instance_count = 3
  }
}