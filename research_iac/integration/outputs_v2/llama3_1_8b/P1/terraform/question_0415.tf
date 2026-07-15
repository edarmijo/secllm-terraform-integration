provider "aws" {
  region = var.aws_region
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "rds-credentials"
  description = "RDS credentials for database access"
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id     = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "rds_instance_role" {
  name        = "rds-instance-role"
  description = "Role for RDS instance to access AWS resources"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "rds_instance_policy" {
  name   = "rds-instance-policy"
  role   = aws_iam_role.rds_instance_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect = "Allow"
        Resource = aws_secretsmanager_secret.rds_credentials.arn
      },
    ]
  })
}

resource "aws_iam_instance_profile" "rds_instance_profile" {
  name = "rds-instance-profile"
  role = aws_iam_role.rds_instance_role.name
}

resource "aws_db_instance" "example" {
  allocated_storage       = var.db_allocated_storage
  engine                  = var.db_engine
  instance_class          = var.db_instance_class
  username                = var.db_username
  password                = aws_secretsmanager_secret_version.rds_credentials.secret_string
  db_name                 = var.db_name
  vpc_security_group_ids  = [aws_security_group.example.id]
  skip_final_snapshot     = true

  tags = {
    Name = "example-rds-instance"
  }
}

resource "aws_security_group" "example" {
  name        = "example-rds-sg"
  description = "Security group for RDS instance"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr_block]
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for RDS instance"
}

variable "db_username" {
  type        = string
  description = "Database username"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Database password"
}

variable "db_allocated_storage" {
  type        = number
  description = "Allocated storage for RDS instance"
}

variable "db_engine" {
  type        = string
  description = "Engine for RDS instance"
}

variable "db_instance_class" {
  type        = string
  description = "Instance class for RDS instance"
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "allowed_cidr_block" {
  type        = string
  description = "Allowed CIDR block for security group ingress"
}