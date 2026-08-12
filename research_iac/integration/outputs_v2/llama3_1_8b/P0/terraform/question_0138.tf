provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "cache_user_role" {
  name        = "ElastiCacheUserRole"
  description = "Allows ElastiCache to access the cache cluster"

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

resource "aws_iam_role_policy" "cache_user_policy" {
  name   = "ElastiCacheUserPolicy"
  role   = aws_iam_role.cache_user_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeCacheSubgroups",
          "elasticache:DescribeCacheParameters",
          "elasticache:ListTagsForResource",
          "elasticache:CreateCacheCluster",
          "elasticache:ModifyCacheCluster",
          "elasticache:DeleteCacheCluster"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "cache_user_group_role" {
  name        = "ElastiCacheUserGroupRole"
  description = "Allows ElastiCache to access the cache cluster"

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
  name   = "ElastiCacheUserGroupPolicy"
  role   = aws_iam_role.cache_user_group_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeCacheSubgroups",
          "elasticache:DescribeCacheParameters",
          "elasticache:ListTagsForResource",
          "elasticache:CreateCacheCluster",
          "elasticache:ModifyCacheCluster",
          "elasticache:DeleteCacheCluster"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_group_membership" "cache_user_group_membership" {
  user_can_change_group = true

  group_ids = [
    aws_iam_group.cache_user_group.id
  ]

  users = [
    aws_iam_user.cache_user.name
  ]
}

resource "aws_iam_group_policy_attachment" "cache_user_group_attach" {
  name       = "ElastiCacheUserGroupAttach"
  roles      = [aws_iam_role.cache_user_group_role.id]
  group_id   = aws_iam_group.cache_user_group.id
}

resource "aws_iam_user" "cache_user" {
  name = "ElastiCacheUser"
}

resource "aws_iam_group" "cache_user_group" {
  name = "ElastiCacheUserGroup"
}