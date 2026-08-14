# Set up an AWS RDS Aurora MySQL cluster with a proxy for enhanced connection management

# VPC configuration
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Environment = "dev"
  }
}

# Subnet configuration
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"

  availability_zone = "us-east-1a"

  tags = {
    Environment = "dev"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"

  availability_zone = "us-east-1b"

  tags = {
    Environment = "dev"
  }
}

# Security group configuration
resource "aws_security_group" "allow_ssh" {
  name   = "allow_ssh"
  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_mysql" {
  name   = "allow_mysql"
  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

# IAM roles and provider configuration
provider "aws" {
  region = "us-east-1"

  # Use least-privilege IAM policies
  assume_role {
    role_arn = "arn:aws:iam::123456789012:role/rds-proxy-assume-role"
  }
}

# Secrets Manager configuration
resource "aws_secretsmanager_secret" "example" {
  name                 = "example-secret"
  description          = "Example secret for RDS proxy"
  recovery_window_in_days = 30

  tags = {
    Environment = "dev"
  }
}

# RDS cluster configuration
resource "aws_rds_cluster" "example" {
  engine           = "aurora-mysql"
  engine_mode      = "SERVERLESS"
  instance_class   = "db.t3.small"

  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"

  # Use least-privilege IAM policies
  db_subnet_group_name = aws_db_subnet_group.example.name
  secret_arn            = aws_secretsmanager_secret.example.arn
  storage_encrypted     = true

  tags = {
    Environment = "dev"
  }
}