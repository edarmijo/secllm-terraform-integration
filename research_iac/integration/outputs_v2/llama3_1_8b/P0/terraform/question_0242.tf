provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "neptune_cluster_execution_role" {
  name        = "neptune-cluster-execution-role"
  description = "Execution role for the Neptune cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "neptune.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "neptune_cluster_execution_role_attach" {
  role       = aws_iam_role.neptune_cluster_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonNeptuneFullAccess"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "neptune-subnet-1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "neptune-subnet-2"
  }
}

resource "aws_neptune_cluster" "example" {
  cluster_identifier           = "example-neptune-cluster"
  engine                       = "neptune"
  instance_class               = "db.r5.large"
  port                         = 8182
  database_name                = "mydatabase"
  master_username              = "admin"
  master_user_password         = "password"
  vpc_security_group_ids       = [aws_security_group.example.id]
  subnet_group_name           = aws_neptune_subnet_group.example.name

  iam_roles {
    role_arn = aws_iam_role.neptune_cluster_execution_role.arn
  }
}

resource "aws_neptune_subnet_group" "example" {
  name       = "neptune-subnet-group"
  description = "Neptune subnet group for the cluster"

  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}