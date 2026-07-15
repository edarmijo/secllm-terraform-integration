# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create an IAM role with the necessary permissions for the PostgreSQL instance
resource "aws_iam_role" "airbyte_rds_role" {
  name        = "AirbyteRDSRole"
  description = "IAM role for Airbyte RDS instance"

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

# Create an IAM policy with the necessary permissions for the PostgreSQL instance
resource "aws_iam_policy" "airbyte_rds_policy" {
  name        = "AirbyteRDSPolicy"
  description = "IAM policy for Airbyte RDS instance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "airbyte_rds_policy_attachment" {
  role       = aws_iam_role.airbyte_rds_role.name
  policy_arn = aws_iam_policy.airbyte_rds_policy.arn
}

# Create a security group for the PostgreSQL instance
resource "aws_security_group" "airbyte_rds_sg" {
  name        = "AirbyteRDSSG"
  description = "Security group for Airbyte RDS instance"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

# Create a subnet group for the PostgreSQL instance
resource "aws_db_subnet_group" "airbyte_rds_subnet_group" {
  name        = "AirbyteRDSSubnetGroup"
  description = "Subnet group for Airbyte RDS instance"

  subnet_ids = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
  ]
}

# Create a PostgreSQL instance within the subnet group
resource "aws_db_instance" "airbyte_rds_instance" {
  identifier             = "AirbyteRDSInstance"
  engine                 = "postgres"
  engine_version         = "15.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  name                   = "airbyte"
  username               = "admin"
  password               = var.rds_password
  port                   = 5432
  publicly_accessible     = true
  vpc_security_group_ids = [aws_security_group.airbyte_rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.airbyte_rds_subnet_group.name
  skip_final_snapshot    = true
}