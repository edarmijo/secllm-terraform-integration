# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create a custom VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "example-vpc" }
}

# Create a subnet in the custom VPC
resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.aws_availability_zone
  tags              = { Name = "example-subnet" }
}

# Create a security group for the PostgreSQL instance
resource "aws_security_group" "example" {
  vpc_id       = aws_vpc.example.id
  name         = "example-sg"
  description  = "Allow inbound traffic on PostgreSQL port"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an IAM role for the PostgreSQL instance
resource "aws_iam_role" "example" {
  name        = "example-rds-role"
  description = "Role for RDS PostgreSQL instance"

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

# Create an IAM policy for the PostgreSQL instance
resource "aws_iam_policy" "example" {
  name        = "example-rds-policy"
  description = "Policy for RDS PostgreSQL instance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:ModifyDBInstance",
          "rds:StartDBInstance",
          "rds:StopDBInstance",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Attach the IAM policy to the role
resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}

# Create a PostgreSQL instance
resource "aws_db_instance" "example" {
  allocated_storage    = 5
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t2.micro"
  username             = var.db_username
  password             = aws_secretsmanager_secret.example.secret_string
  vpc_security_group_ids = [aws_security_group.example.id]
  db_subnet_group_name = aws_db_subnet_group.example.name

  maintenance_window = "mon:00:00-mon:03:00"

  tags = { Name = "example-rds" }
}

# Create a DB subnet group
resource "aws_db_subnet_group" "example" {
  name       = "example-db-subnet-group"
  description = "DB subnet group for RDS PostgreSQL instance"
  subnet_ids = [aws_subnet.example.id]
}