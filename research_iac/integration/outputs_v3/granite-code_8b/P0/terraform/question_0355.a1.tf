# Configure the AWS provider
provider "aws" {
  region = var.region
}

# Create a VPC with subnets in two availability zones
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Environment = "dev"
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones for the subnets"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.availability_zones[0]

  tags = {
    Environment = "dev"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"
  availability_zone = var.availability_zones[1]

  tags = {
    Environment = "dev"
  }
}

# Create a security group for the RDS cluster
resource "aws_security_group" "rds" {
  name   = "rds-sg"
  description = "Security group for the RDS cluster"
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "dev"
  }
}

# Create an IAM role for the RDS cluster
resource "aws_iam_role" "rds" {
  name = "rds-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Environment = "dev"
  }
}

# Create a secrets manager secret for the database credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "db-credentials"
  description = "Database credentials for the RDS cluster"
}

# Create an RDS Aurora MySQL cluster with a proxy
resource "aws_rds_cluster" "example" {
  engine           = "aurora-mysql"
  engine_mode      = "SERVERLESS"
  instance_class   = "db.t3.small"
  availability_zones = var.availability_zones
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  storage_encrypted = true
  secret_store_credentials {
    kms_key_id = aws_kms_key.example.arn
  }

  db_subnet_group_name = aws_db_subnet_group.example.name
  security_groups       = [aws_security_group.rds.id]
  parameter_group_name  = aws_rds_parameter_group.example.name
  skip_final_snapshot   = true

  tags = {
    Environment = "dev"
  }
}