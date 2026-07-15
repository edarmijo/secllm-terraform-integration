provider "aws" {
  region = var.region
}

# Create VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "example-vpc" }
}

# Create subnets
resource "aws_subnet" "example" {
  count             = 2
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.${count.index}.0/24"
  availability_zone = "${var.region}a"
  tags              = { Name = "example-subnet-${count.index}" }
}

# Create security group for RDS Aurora cluster
resource "aws_security_group" "rds" {
  name        = "example-rds-sg"
  description = "Security group for RDS Aurora cluster"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.example.cidr_block]
  }
}

# Create IAM role for RDS Aurora cluster
resource "aws_iam_role" "rds" {
  name        = "example-rds-role"
  description = "IAM role for RDS Aurora cluster"

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

# Create IAM policy for RDS Aurora cluster
resource "aws_iam_policy" "rds" {
  name        = "example-rds-policy"
  description = "IAM policy for RDS Aurora cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:DescribeClusters",
          "rds:CreateCluster",
          "rds:ModifyCluster",
          "rds:DeleteCluster",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Attach IAM policy to IAM role
resource "aws_iam_role_policy_attachment" "rds" {
  role       = aws_iam_role.rds.name
  policy_arn = aws_iam_policy.rds.arn
}

# Create Secrets Manager secret for RDS Aurora cluster credentials
resource "aws_secretsmanager_secret" "rds" {
  name        = "example-rds-secret"
  description = "Secrets for RDS Aurora cluster"
}

# Create IAM role for Secrets Manager access
resource "aws_iam_role" "secrets_manager" {
  name        = "example-secrets-manager-role"
  description = "IAM role for Secrets Manager access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
      },
    ]
  })
}

# Create IAM policy for Secrets Manager access
resource "aws_iam_policy" "secrets_manager" {
  name        = "example-secrets-manager-policy"
  description = "IAM policy for Secrets Manager access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.rds.arn
      },
    ]
  })
}

# Attach IAM policy to IAM role
resource "aws_iam_role_policy_attachment" "secrets_manager" {
  role       = aws_iam_role.secrets_manager.name
  policy_arn = aws_iam_policy.secrets_manager.arn
}

# Create RDS Aurora cluster
resource "aws_rds_cluster" "example" {
  cluster_identifier = "example-rds-cluster"
  engine             = "aurora-mysql"
  instance_class     = "db.r5.large"
  database_name      = "mydatabase"
  master_username    = aws_secretsmanager_secret_version.rds.username
  master_password    = aws_secretsmanager_secret_version.rds.password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.example.name

  iam_database_authentication_enabled = true
}

# Create RDS Aurora cluster instance
resource "aws_rds_cluster_instance" "example" {
  identifier          = "example-rds-instance"
  cluster_identifier = aws_rds_cluster.example.id
  instance_class     = "db.r5.large"
  engine             = aws_rds_cluster.example.engine

  vpc_security_group_ids = [aws_security_group.rds.id]
}

# Create Secrets Manager secret version for RDS Aurora cluster credentials
resource "aws_secretsmanager_secret_version" "rds" {
  secret_id     = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    username = "myusername"
    password = "mypassword"
  })
}