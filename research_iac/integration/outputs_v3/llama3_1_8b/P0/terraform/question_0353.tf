provider "aws" {
  region = "us-west-2"
}

# Create VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "example-vpc" }
}

# Create subnets
resource "aws_subnet" "example" {
  count             = 3
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.${count.index}.0/24"
  availability_zone = "${var.region}${count.index}"
}

# Create security group for RDS
resource "aws_security_group" "example_rds" {
  name        = "example-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create IAM role for RDS
resource "aws_iam_role" "example_rds" {
  name        = "example-rds-role"
  description = "IAM role for RDS instance"

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

# Create IAM policy for RDS
resource "aws_iam_policy" "example_rds" {
  name        = "example-rds-policy"
  description = "IAM policy for RDS instance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:ModifyDBInstance",
          "rds:ModifyDBCluster",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Attach IAM policy to role
resource "aws_iam_role_policy_attachment" "example_rds" {
  role       = aws_iam_role.example_rds.name
  policy_arn = aws_iam_policy.example_rds.arn
}

# Create RDS Aurora cluster
resource "aws_rds_cluster" "example" {
  cluster_identifier      = "example-cluster"
  engine                  = "aurora-mysql"
  instance_class          = "db.r5.large"
  database_name           = "mydb"
  master_username         = "admin"
  master_password         = aws_secretsmanager_secret.example_rds_secret.secret_string
  vpc_security_group_ids  = [aws_security_group.example_rds.id]
  db_subnet_group_name    = aws_db_subnet_group.example.name

  iam_database_authentication_enabled = true
}

# Create RDS Aurora instance
resource "aws_rds_cluster_instance" "example" {
  cluster_identifier      = aws_rds_cluster.example.cluster_identifier
  instance_class          = "db.r5.large"
  engine                  = aws_rds_cluster.example.engine
  identifier              = "example-instance"
  db_subnet_group_name    = aws_db_subnet_group.example.name

  vpc_security_group_ids  = [aws_security_group.example_rds.id]
}

# Create Secrets Manager secret for RDS credentials
resource "aws_secretsmanager_secret" "example_rds_secret" {
  name        = "example-rds-secret"
  description = "Secrets for RDS instance"

  recovery_window_in_days = 30

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Allow access to the secret from the RDS service"
        Effect    = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action   = ["secretsmanager:GetSecretValue"]
      },
    ]
  })
}

# Create Secrets Manager secret value
resource "aws_secretsmanager_secret_version" "example_rds_secret_value" {
  secret_id     = aws_secretsmanager_secret.example_rds_secret.id
  secret_string = "{\"username\":\"admin\",\"password\":\"${random_password.password.result}\"}"
}