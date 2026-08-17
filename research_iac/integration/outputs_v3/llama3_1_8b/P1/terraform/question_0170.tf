provider "aws" {
  region = "us-west-2"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret" "dax_cluster_secret" {
  name = "dax-cluster-credentials"
}

data "aws_secretsmanager_secret_version" "dax_cluster_secret_version" {
  secret_id = data.aws_secretsmanager_secret.dax_cluster_secret.id
}

locals {
  dax_cluster_credentials = jsondecode(data.aws_secretsmanager_secret_version.dax_cluster_secret_version.secret_string)
}

resource "aws_dax_subnet_group" "example" {
  name       = "example-dax-subnet-group"
  description = "Example DAX subnet group"
  subnet_ids = [
    "subnet-12345678",
    "subnet-90123456"
  ]
}

resource "aws_iam_role" "dax_cluster_role" {
  name        = "dax-cluster-role"
  description = "DAX cluster IAM role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dax.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "dax_cluster_policy" {
  name   = "dax-cluster-policy"
  role   = aws_iam_role.dax_cluster_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dax:CreateCluster",
          "dax:DeleteCluster",
          "dax:DescribeClusters",
          "dax:ListTagsForResource",
          "dax:TagResource",
          "dax:UntagResource",
          "dax:UpdateCluster"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "dax_cluster_instance_profile" {
  name = "dax-cluster-instance-profile"
  role = aws_iam_role.dax_cluster_role.name
}

resource "aws_security_group" "dax_cluster_sg" {
  name        = "dax-cluster-sg"
  description = "DAX cluster security group"
  vpc_id      = "vpc-12345678"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_dax_cluster" "example" {
  cluster_name = "example-dax-cluster"
  iam_role_arn = aws_iam_role.dax_cluster_role.arn
  subnet_group_name = aws_dax_subnet_group.example.name
  preferred_maintenance_window = "sun:03:00-sun:04:00"
  notification_configuration {
    topic_arn = "arn:aws:sns:us-west-2:123456789012:dax-cluster-notifications"
  }
}