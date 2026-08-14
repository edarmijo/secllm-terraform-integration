provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

resource "aws_vpc" "rds_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "rds_subnets" {
  count             = 3
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = "${var.region}${count.index}"
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "RDS Security Group"
  vpc_id      = aws_vpc.rds_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "rds_iam_role" {
  name        = "rds-iam-role"
  description = "RDS IAM Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "rds_iam_policy" {
  name   = "rds-iam-policy"
  role   = aws_iam_role.rds_iam_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:ModifyDBInstance",
          "rds:ModifyDBCluster",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_rds_cluster" "rds_cluster" {
  cluster_identifier = "rds-cluster"
  engine             = "aurora-mysql"
  instance_class     = "db.r5.large"
  database_name      = "mydb"
  master_username    = "admin"
  master_password    = aws_secretsmanager_secret.rds_secret.secret_string
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  backup_retention_period = "5 days"
  preferred_backup_window = "07:00-09:00"

  iam_database_authentication_enabled = true

  tags = {
    Name = "rds-cluster"
  }
}

resource "aws_rds_cluster_instance" "rds_instances" {
  count              = 2
  cluster_identifier = aws_rds_cluster.rds_cluster.id
  instance_class     = "db.r5.large"
  engine             = "aurora-mysql"
  database_name      = "mydb"
  master_username    = "admin"
  master_password    = aws_secretsmanager_secret.rds_secret.secret_string

  tags = {
    Name = "rds-instance-${count.index}"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  description = "RDS Subnet Group"

  subnet_ids = aws_subnet.rds_subnets.*.id
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name = "rds-secret"
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id     = aws_secretsmanager_secret.rds_secret.id
  secret_string = "mysecretpassword"
}