# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create an IAM role for the database instance
resource "aws_iam_role" "database_instance" {
  name        = "${var.database_name}-instance-role"
  description = "IAM role for the database instance"

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

# Create an IAM policy for the database instance
resource "aws_iam_policy" "database_instance" {
  name        = "${var.database_name}-instance-policy"
  description = "IAM policy for the database instance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:CreateDBInstance",
          "rds:ModifyDBInstance",
          "rds:DeleteDBInstance"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach the IAM policy to the role
resource "aws_iam_role_policy_attachment" "database_instance" {
  role       = aws_iam_role.database_instance.name
  policy_arn = aws_iam_policy.database_instance.arn
}

# Create an AWS Secrets Manager secret for database credentials
resource "aws_secretsmanager_secret" "database_credentials" {
  name        = "${var.database_name}-credentials"
  description = "Secrets for the database instance"

  # Store the secret in a secure location (e.g., AWS Secrets Manager)
  # Use a data source to retrieve the secret value
  data_source = "arn:aws:secretsmanager:${var.aws_region}:${var.account_id}:secret/${var.database_name}-credentials"
}

# Create an IAM role for the database instance with least-privilege permissions
resource "aws_iam_role" "database_instance_least_privilege" {
  name        = "${var.database_name}-instance-role-least-privilege"
  description = "IAM role for the database instance with least-privilege permissions"

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

# Create an IAM policy for the database instance with least-privilege permissions
resource "aws_iam_policy" "database_instance_least_privilege" {
  name        = "${var.database_name}-instance-policy-least-privilege"
  description = "IAM policy for the database instance with least-privilege permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach the IAM policy to the role
resource "aws_iam_role_policy_attachment" "database_instance_least_privilege" {
  role       = aws_iam_role.database_instance_least_privilege.name
  policy_arn = aws_iam_policy.database_instance_least_privilege.arn
}