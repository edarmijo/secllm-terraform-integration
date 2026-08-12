provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "cache_user" {
  name        = "${var.cache_cluster_name}-user-role"
  description = "ElastiCache user role"

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

resource "aws_iam_role_policy" "cache_user" {
  name   = "${var.cache_cluster_name}-user-policy"
  role   = aws_iam_role.cache_user.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticache:CreateCacheParameterGroup",
          "elasticache:DescribeCacheParameterGroups",
          "elasticache:ModifyCacheParameterGroup",
          "elasticache:DeleteCacheParameterGroup",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "cache_user_group" {
  name        = "${var.cache_cluster_name}-user-group-role"
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

resource "aws_iam_role_policy" "cache_user_group" {
  name   = "${var.cache_cluster_name}-user-group-policy"
  role   = aws_iam_role.cache_user_group.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticache:CreateCacheParameterGroup",
          "elasticache:DescribeCacheParameterGroups",
          "elasticache:ModifyCacheParameterGroup",
          "elasticache:DeleteCacheParameterGroup",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_user" "cache_user" {
  name = var.cache_user_name
}

resource "aws_iam_group_membership" "cache_user_group" {
  name = "${var.cache_cluster_name}-user-group"

  users = [aws_iam_user.cache_user.name]
  group = aws_iam_group.cache_user_group.name
}

resource "aws_iam_group" "cache_user_group" {
  name = "${var.cache_cluster_name}-user-group"
}

resource "aws_iam_policy_attachment" "cache_user_attach" {
  name       = "${var.cache_cluster_name}-user-attach"
  roles      = [aws_iam_role.cache_user.id]
  policy_arn = aws_iam_policy.cache_user.arn
}

resource "aws_iam_policy_attachment" "cache_user_group_attach" {
  name       = "${var.cache_cluster_name}-user-group-attach"
  roles      = [aws_iam_role.cache_user_group.id]
  policy_arn = aws_iam_policy.cache_user_group.arn
}