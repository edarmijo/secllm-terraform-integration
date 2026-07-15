provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_redshift_cluster" "example" {
  cluster_identifier      = "example-cluster"
  node_type               = "dc2.large"
  number_of_nodes         = 2
  cluster_subnet_group_name = aws_redshift_cluster_subnet_group.example.name

  vpc_security_group_ids = [aws_security_group.example.id]

  iam_roles = [
    aws_iam_role.redshift.arn,
  ]
}

resource "aws_redshift_cluster_subnet_group" "example" {
  name        = "example-cluster-subnet-group"
  description = "example cluster subnet group"

  vpc_id = var.vpc_id
}

resource "aws_security_group" "example" {
  name        = "example-redshift-sg"
  description = "example redshift security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }
}

resource "aws_iam_role" "redshift" {
  name        = "example-redshift-role"
  description = "example redshift role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "redshift" {
  name   = "example-redshift-policy"
  role   = aws_iam_role.redshift.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "redshift:DescribeClusters",
          "redshift:DescribeClusters",
          "redshift:GetClusterCredentials",
          "redshift:CreateCluster",
          "redshift:DeleteCluster",
          "redshift:ModifyCluster",
          "redshift:RestoreClusterSnapshot",
          "redshift:RevokeClusterSecurityGroupInboundRule",
        ]
        Resource = "*"
        Effect    = "Allow"
      },
    ]
  })
}

resource "aws_iam_role" "endpoint_authorization" {
  name        = "example-redshift-endpoint-authorization-role"
  description = "example redshift endpoint authorization role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "endpoint_authorization" {
  name   = "example-redshift-endpoint-authorization-policy"
  role   = aws_iam_role.endpoint_authorization.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "redshift:CreateClusterUser",
          "redshift:GetClusterCredentials",
          "redshift:DescribeClusters",
        ]
        Resource = "*"
        Effect    = "Allow"
      },
    ]
  })
}

resource "aws_redshift_cluster_endpoint" "example" {
  cluster_identifier = aws_redshift_cluster.example.id
  endpoint_name     = "example-endpoint"

  vpc_security_group_ids = [aws_security_group.example.id]

  iam_role_arn = aws_iam_role.endpoint_authorization.arn

  port = 5439
}

resource "aws_secretsmanager_secret" "redshift_credentials" {
  name = "example-redshift-credentials"
}

resource "aws_secretsmanager_secret_version" "redshift_credentials" {
  secret_id     = aws_secretsmanager_secret.redshift_credentials.id
  secret_string = jsonencode({
    username = "username"
    password = "password"
  })
}