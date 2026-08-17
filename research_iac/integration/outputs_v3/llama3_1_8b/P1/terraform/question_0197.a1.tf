provider "aws" {
  region = "us-west-2"
}

data "aws_secretsmanager_secret" "cache_password" {
  name = "cache-password"
}

data "aws_secretsmanager_secret_version" "cache_password" {
  secret_id = data.aws_secretsmanager_secret.cache_password.id
}

resource "aws_iam_role" "cache_user_group" {
  name        = "cache-user-group"
  description = "ElastiCache user group role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "cache_user_group_policy" {
  name        = "cache-user-group-policy"
  description = "ElastiCache user group policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticache:CreateCacheCluster",
          "elasticache:CreateCacheParameterGroup",
          "elasticache:CreateCacheSubnetGroup",
          "elasticache:CreateReplicationGroup",
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeCacheParameterGroups",
          "elasticache:DescribeCacheSubnetGroups",
          "elasticache:DescribeReplicationGroups",
          "elasticache:ListTagsForResource",
          "elasticache:ListTagsForResource",
          "elasticache:TagResource",
          "elasticache:UntagResource",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cache_user_group_attach" {
  role       = aws_iam_role.cache_user_group.name
  policy_arn = aws_iam_policy.cache_user_group_policy.arn
}

resource "aws_iam_group" "cache_user_group" {
  name = "cache-user-group"
}

resource "aws_iam_group_policy_attachment" "cache_user_group_attach" {
  group      = aws_iam_group.cache_user_group.name
  policy_arn = aws_iam_policy.cache_user_group_policy.arn
}

resource "aws_iam_user" "cache_user1" {
  name = "cache-user1"
  path = "/"

  // Removed policies argument
}

resource "aws_iam_user" "cache_user2" {
  name = "cache-user2"
  path = "/"

  // Removed policies argument
}

resource "aws_iam_user" "cache_user3" {
  name = "cache-user3"
  path = "/"

  // Removed policies argument
}

resource "aws_iam_group_membership" "cache_user_group_membership" {
  name = "cache-user-group-membership"

  users = [
    aws_iam_user.cache_user1.name,
    aws_iam_user.cache_user2.name,
    aws_iam_user.cache_user3.name,
  ]

  group = aws_iam_group.cache_user_group.name
}