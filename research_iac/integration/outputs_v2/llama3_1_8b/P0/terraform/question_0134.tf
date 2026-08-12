provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "elasticacluster" {
  name        = "ElastiCacheClusterRole"
  description = "Allows ElastiCache to call other AWS services on your behalf."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticache.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "elasticacluster" {
  name   = "ElastiCacheClusterPolicy"
  role   = aws_iam_role.elasticacluster.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeInstances",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "elasticaclusterinstance" {
  name        = "ElastiCacheClusterInstanceRole"
  description = "Allows ElastiCache to call other AWS services on your behalf."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticache.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "elasticaclusterinstance" {
  name   = "ElastiCacheClusterInstancePolicy"
  role   = aws_iam_role.elasticaclusterinstance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeInstances",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_elasticache_cluster" "example" {
  cluster_id       = "my-redis-cluster"
  engine           = "redis"
  node_type        = "cache.t3.micro"
  num_cache_nodes  = 1
  parameter_group_name = "default.redis6.x"

  iam_role_name      = aws_iam_role.elasticaclusterinstance.name

  port               = 6379
}