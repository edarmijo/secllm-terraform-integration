provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "aurora_mysql_cluster_role" {
  name        = "AuroraMySQLClusterRole"
  description = "Trust role for the Aurora MySQL cluster"

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

resource "aws_iam_role_policy" "aurora_mysql_cluster_policy" {
  name   = "AuroraMySQLClusterPolicy"
  role   = aws_iam_role.aurora_mysql_cluster_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:DescribeClusters",
          "rds:ModifyCluster",
          "rds:DeleteCluster",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "aurora_mysql_instance_role" {
  name        = "AuroraMySQLInstanceRole"
  description = "Trust role for the Aurora MySQL instance"

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

resource "aws_iam_role_policy" "aurora_mysql_instance_policy" {
  name   = "AuroraMySQLInstancePolicy"
  role   = aws_iam_role.aurora_mysql_instance_role.id

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
      }
    ]
  })
}

resource "aws_rds_cluster" "example" {
  cluster_identifier      = "aurora-mysql-cluster"
  engine                  = "aurora-mysql"
  instance_class          = "db.r5.large"
  database_name           = "mydb"
  master_username         = "admin"
  master_password         = "password"
  vpc_security_group_ids  = [aws_security_group.example.id]
  db_subnet_group_name    = aws_db_subnet_group.example.name
}

resource "aws_rds_cluster_instance" "example" {
  cluster_identifier      = aws_rds_cluster.example.cluster_identifier
  instance_class          = "db.r5.large"
  engine                  = aws_rds_cluster.example.engine
  database_name           = aws_rds_cluster.example.database_name
  master_username         = aws_rds_cluster.example.master_username
  master_password         = aws_rds_cluster.example.master_password
}

resource "aws_db_subnet_group" "example" {
  name       = "aurora-mysql-subnet-group"
  subnet_ids = [aws_subnet.example.id]
}

resource "aws_security_group" "example" {
  name        = "aurora-mysql-sg"
  description = "Allow inbound traffic on port 3306"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "aurora-mysql-subnet"
  }
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}