# Configure AWS Provider
provider "aws" {
  region = var.region
}

# Create IAM Role for RDS MySQL Instance
resource "aws_iam_role" "rds_mysql_instance" {
  name        = "${var.environment}-rds-mysql-instance-role"
  description = "Role for RDS MySQL instance"

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

# Create IAM Policy for RDS MySQL Instance
resource "aws_iam_policy" "rds_mysql_instance_policy" {
  name        = "${var.environment}-rds-mysql-instance-policy"
  description = "Policy for RDS MySQL instance"

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
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBSnapshots",
          "rds:CreateDBInstance",
          "rds:ModifyDBInstance",
          "rds:DeleteDBInstance",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Attach IAM Policy to Role
resource "aws_iam_role_policy_attachment" "rds_mysql_instance_attach" {
  role       = aws_iam_role.rds_mysql_instance.name
  policy_arn = aws_iam_policy.rds_mysql_instance_policy.arn
}

# Create RDS MySQL Instance
resource "aws_rds_cluster_instance" "mysql_instance" {
  cluster_identifier      = "${var.environment}-rds-mysql-cluster"
  instance_class          = var.instance_class
  engine                  = "mysql"
  database_name           = var.database_name
  username                = var.username
  password                = aws_secretsmanager_secret.rds_mysql_password.secret_string
  skip_final_snapshot     = true
  apply_immediately       = true

  vpc_security_group_ids = [aws_security_group.mysql_sg.id]

  iam_instance_profile {
    name = aws_iam_role.rds_mysql_instance.name
  }
}

# Create Security Group for RDS MySQL Instance
resource "aws_security_group" "mysql_sg" {
  name        = "${var.environment}-rds-mysql-sg"
  description = "Security group for RDS MySQL instance"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr_block]
  }
}

# Create Secrets Manager Secret for RDS MySQL Password
resource "aws_secretsmanager_secret" "rds_mysql_password" {
  name        = "${var.environment}-rds-mysql-password"
  description = "Secret for RDS MySQL password"

  recovery_window_in_days = 0

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Allow access to the secret from AWS services"
        Effect    = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "secretsmanager:GetSecretValue",
        ]
      },
    ]
  })
}

# Create Secrets Manager Secret Value for RDS MySQL Password
resource "aws_secretsmanager_secret_version" "rds_mysql_password_value" {
  secret_id     = aws_secretsmanager_secret.rds_mysql_password.id
  secret_string = var.rds_mysql_password
}