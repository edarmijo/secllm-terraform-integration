provider "aws" {
  region = var.region
}

data "aws_secretsmanager_secret_version" "cache_password" {
  secret_id = var.cache_password_secret_id
}

resource "aws_elasticache_cluster" "example" {
  cluster_id           = "my-redis-cluster"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1

  parameter_group_name = "default.redis6.x"

  port             = 6379
  snapshot_window  = "30m"
  snapshot_retention_limit = 8

  maintenance_window           = "sun:05:00-sun:06:00"
  preferred_maintenance_window = "sun:05:00-sun:06:00"

  vpc_security_group_ids = [aws_security_group.elasticache.id]

  tags = {
    Environment = "dev"
  }
}

resource "aws_elasticache_parameter_group" "example" {
  name        = "my-redis-parameter-group"
  family      = "redis6.x"

  parameter {
    name  = "rdbsaveinterval"
    value = 3600
  }

  parameter {
    name  = "maxmemory-policy"
    value = "volatile-lru"
  }
}

resource "aws_security_group" "elasticache" {
  name        = "my-redis-sg"
  description = "Allow inbound traffic on port 6379"

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.elasticache_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "elasticache" {
  name        = "my-redis-role"
  description = "Allow Elasticache to manage Redis cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticache.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "elasticache" {
  name   = "my-redis-policy"
  role   = aws_iam_role.elasticache.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticache:CreateCacheCluster",
          "elasticache:DeleteCacheCluster",
          "elasticache:UpdateCacheCluster",
          "elasticache:DescribeCacheClusters",
          "elasticache:ListTagsForResource",
          "elasticache:TagResource",
          "elasticache:UntagResource",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "elasticache" {
  name = "my-redis-instance-profile"

  role = aws_iam_role.elasticache.name
}