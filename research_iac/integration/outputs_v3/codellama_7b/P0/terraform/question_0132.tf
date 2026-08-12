provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "memcached_cluster" {
  name        = "MemcachedClusterRole"
  description = "Role for Memcached cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "memcached_cluster" {
  name   = "MemcachedClusterPolicy"
  role   = aws_iam_role.memcached_cluster.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticache:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_elasticache_cluster" "memcached_cluster" {
  cluster_id           = "MemcachedCluster"
  engine               = "memcached"
  node_type            = "cache.t2.small"
  num_cache_nodes      = 1
  parameter_group_name = "default.memcached1.5"
}