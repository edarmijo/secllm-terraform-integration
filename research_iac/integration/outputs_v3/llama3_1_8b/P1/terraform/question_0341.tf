provider "aws" {
  region = "us-west-2"
}

# AWS Secrets Manager for database credentials
resource "aws_secretsmanager_secret" "database_credentials" {
  name = "database-credentials"
}

resource "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id     = aws_secretsmanager_secret.database_credentials.id
  secret_string = jsonencode({"username": "myuser", "password": "mypassword"})
}

# IAM role for RDS instance
resource "aws_iam_role" "rds_instance_role" {
  name        = "rds-instance-role"
  description = "Role for RDS instance"

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
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject"
        ]
        Effect = "Allow"
        Resource = "arn:aws:s3:::my-bucket/*"
      }
    ]
  })
}

# IAM instance profile for RDS instance
resource "aws_iam_instance_profile" "rds_instance_profile" {
  name = "rds-instance-profile"
  role = aws_iam_role.rds_instance_role.name
}

# VPC and subnets
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
}

# Security group for database access
resource "aws_security_group" "database_sg" {
  name        = "database-sg"
  description = "Security group for database access"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS instance
resource "aws_db_instance" "main_rds" {
  allocated_storage    = 20
  engine               = "postgres"
  instance_class       = "db.t3.medium"
  name                 = "mydb"
  username             = aws_secretsmanager_secret_version.database_credentials.secret_string.username
  password             = aws_secretsmanager_secret_version.database_credentials.secret_string.password
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  vpc_id               = aws_vpc.main_vpc.id
  subnet_id            = aws_subnet.subnet1.id
  publicly_accessible  = true
  skip_final_snapshot  = true
}

output "database_endpoint" {
  value = aws_db_instance.main_rds.endpoint
}