provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Example VPC"
  }
}

resource "aws_subnet" "example" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Example Subnet"
  }
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Security group for example"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_iam_role" "example" {
  name        = "example-role"
  description = "IAM role for example"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "rds.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_secretsmanager_secret" "example" {
  name       = "example-secret"
  kms_key_id = aws_kms_key.example.arn
}

resource "aws_kms_key" "example" {
  description             = "KMS key for example"
  deletion_window_in_days = 7
}

resource "aws_rds_cluster" "example" {
  cluster_identifier        = "example-aurora-mysql-cluster"
  engine                    = "aurora-mysql"
  engine_version            = "5.7.mysql_aurora.2.03.1"
  availability_zones        = ["us-east-1a", "us-east-1b"]
  database_name             = "example"
  master_username           = "admin"
  master_password           = aws_secretsmanager_secret.example.arn
  backup_retention_period   = 5
  preferred_backup_window   = "07:00-09:00"
  preferred_maintenance_window = "sun:10:00-sun:10:30"
  vpc_security_group_ids    = [aws_security_group.example.id]
  db_subnet_group_name      = aws_db_subnet_group.example.name
}

resource "aws_rds_cluster_instance" "example" {
  identifier           = "example-aurora-mysql-cluster-instance"
  cluster_identifier   = aws_rds_cluster.example.id
  instance_class       = "db.t3.medium"
  engine               = "aurora-mysql"
  engine_version       = "5.7.mysql_aurora.2.03.1"
  db_parameter_group   = aws_db_parameter_group.example.id
  db_cluster_parameter_group = aws_rds_cluster_parameter_group.example.id
}

resource "aws_db_subnet_group" "example" {
  name       = "example-aurora-mysql-subnet-group"
  subnet_ids = [aws_subnet.example.id]
}

resource "aws_db_parameter_group" "example" {
  name        = "example-aurora-mysql-parameter-group"
  family      = "aurora-mysql5.7"
  description = "Parameter group for example"
}

resource "aws_rds_cluster_parameter_group" "example" {
  name        = "example-aurora-mysql-cluster-parameter-group"
  family      = "aurora-mysql5.7"
  description = "Cluster parameter group for example"
}