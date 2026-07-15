provider "aws" {
  region = "us-east-1"
}

resource "aws_memcached_cluster" "example" {
  name = "my-memcached-cluster"
  node_type = "t2.micro"
  num_nodes = 3
  engine_version = "1.6.6"
  auto_scaling_enabled = true
}