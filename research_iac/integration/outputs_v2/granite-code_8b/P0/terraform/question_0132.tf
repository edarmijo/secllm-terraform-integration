provider "aws" {
  region = "us-east-1"
}

resource "aws_memcached_cluster" "example" {
  cluster_name        = "my-memcached-cluster"
  engine              = "memcached"
  node_type           = "cache.t2.small"
  num_nodes           = 3
  parameter_group_name = aws_memcached_parameter_group.example.name
  security_group_ids   = [aws_security_group.example.id]
  subnet_group_name    = aws_memcached_subnet_group.example.name

  tags = {
    Environment = "production"
  }
}