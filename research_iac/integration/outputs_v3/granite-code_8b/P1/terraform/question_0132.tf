provider "aws" {
  region = var.region
}

resource "aws_memcached_cluster" "example" {
  cluster_name    = "example-memcached-cluster"
  node_type       = "cache.t2.micro"
  num_nodes       = 3
  parameter_group_name = aws_memcached_parameter_group.example.name

  security_group_ids = [
    aws_security_group.example.id,
  ]

  subnet_group_name = aws_memcached_subnet_group.example.name
}