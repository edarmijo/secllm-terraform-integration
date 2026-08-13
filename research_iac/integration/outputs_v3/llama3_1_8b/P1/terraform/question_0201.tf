provider "aws" {
  region = "us-east-1"
}

data "aws_secretsmanager_secret" "msk_cluster_password" {
  name = "MSKClusterPassword"
}

resource "aws_iam_role" "msk_cluster_role" {
  name        = "MSKClusterRole"
  description = "Managed MSK cluster IAM role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kafka.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "msk_cluster_policy" {
  name        = "MSKClusterPolicy"
  description = "Managed MSK cluster IAM policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kafka:CreateConfiguration",
          "kafka:DeleteConfiguration",
          "kafka:DescribeConfiguration",
          "kafka:GetConfiguration",
          "kafka:ListConfigurations",
          "kafka:UpdateConfiguration",
          "kafka:CreateCluster",
          "kafka:DeleteCluster",
          "kafka:DescribeCluster",
          "kafka:GetCluster",
          "kafka:ListClusters",
          "kafka:UpdateCluster"
        ]
        Effect = "Allow"
        Resource = aws_msk_cluster.msk_cluster.arn
      },
      {
        Action = [
          "iam:PassRole"
        ]
        Effect = "Allow"
        Resource = aws_iam_role.msk_cluster_role.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "msk_cluster_attach" {
  role       = aws_iam_role.msk_cluster_role.name
  policy_arn = aws_iam_policy.msk_cluster_policy.arn
}

resource "aws_msk_cluster" "msk_cluster" {
  cluster_name           = "managed-msk-cluster"
  kafka_version          = "2.6.1"
  number_of_broker_nodes = 3
  broker_node_type       = "kafka.m5.large"
  subnet_ids             = [aws_subnet.msk_subnet.id]
  vpc_security_group_ids = [aws_security_group.msk_sg.id]

  configuration {
    arn      = aws_msk_configuration.msk_config.arn
    revision = aws_msk_configuration.msk_config.latest_revision
  }
}

resource "aws_msk_configuration" "msk_config" {
  name       = "managed-msk-config"
  kafka_version = "2.6.1"

  configuration {
    arn      = aws_msk_cluster.msk_cluster.arn
    revision = aws_msk_cluster.msk_cluster.latest_revision
  }
}

resource "aws_security_group" "msk_sg" {
  name        = "managed-msk-sg"
  description = "Managed MSK security group"

  ingress {
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "msk_subnet" {
  name            = "managed-msk-subnet"
  cidr_block      = "10.0.1.0/24"
  vpc_id          = aws_vpc.msk_vpc.id
  availability_zone = "us-east-1a"

  tags = {
    Name = "managed-msk-subnet"
  }
}

resource "aws_vpc" "msk_vpc" {
  name            = "managed-msk-vpc"
  cidr_block      = "10.0.0.0/16"

  tags = {
    Name = "managed-msk-vpc"
  }
}