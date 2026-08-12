provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret" "neptune_cluster_credentials" {
  name = "neptune-cluster-credentials"
}

resource "aws_iam_role" "neptune_cluster_execution_role" {
  name               = "neptune-cluster-execution-role"
  description        = "Execution role for the Neptune cluster"

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

resource "aws_iam_role_policy" "neptune_cluster_execution_policy" {
  name   = "neptune-cluster-execution-policy"
  role   = aws_iam_role.neptune_cluster_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:CreateCluster",
          "rds:ModifyCluster",
          "rds:DeleteCluster",
          "rds:DescribeClusters",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "neptune_cluster_execution_profile" {
  name = "neptune-cluster-execution-profile"
  role = aws_iam_role.neptune_cluster_execution_role.name
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_subnet" "neptune_cluster_subnet1" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.aws_availability_zone

  tags = {
    Name = "neptune-cluster-subnet-1"
  }
}

resource "aws_subnet" "neptune_cluster_subnet2" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.aws_availability_zone

  tags = {
    Name = "neptune-cluster-subnet-2"
  }
}

resource "aws_db_subnet_group" "neptune_cluster_subnet_group" {
  name       = "neptune-cluster-subnet-group"
  description = "Subnet group for the Neptune cluster"

  subnet_ids = [aws_subnet.neptune_cluster_subnet1.id, aws_subnet.neptune_cluster_subnet2.id]
}