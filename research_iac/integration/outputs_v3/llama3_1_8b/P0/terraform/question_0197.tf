provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "cache_user_group" {
  name        = "cache_user_group"
  description = "ElastiCache user group role"

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

resource "aws_iam_role_policy" "cache_user_group_policy" {
  name   = "cache_user_group_policy"
  role   = aws_iam_role.cache_user_group.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticache:CreateCacheCluster",
          "elasticache:CreateCacheParameterGroup",
          "elasticache:CreateCacheSubnetGroup",
          "elasticache:CreateReplicationGroup",
          "elasticache:DeleteCacheCluster",
          "elasticache:DeleteCacheParameterGroup",
          "elasticache:DeleteCacheSubnetGroup",
          "elasticache:DeleteReplicationGroup",
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeCacheParameterGroups",
          "elasticache:DescribeCacheSubnetGroups",
          "elasticache:DescribeReplicationGroups",
          "elasticache:ListTagsForResource",
          "elasticache:ListTagsForResource",
          "elasticache:RebootCacheCluster",
          "elasticache:UpdateCacheCluster",
          "elasticache:UpdateCacheParameterGroup",
          "elasticache:UpdateCacheSubnetGroup",
          "elasticache:UpdateReplicationGroup",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_group_membership" "cache_user_group_membership" {
  name = "cache_user_group_membership"

  users = [
    "user1",
    "user2",
    "user3"
  ]

  group = aws_iam_role.cache_user_group.name
}