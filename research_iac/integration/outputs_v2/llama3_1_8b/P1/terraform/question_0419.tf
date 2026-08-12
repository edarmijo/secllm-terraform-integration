provider "aws" {
  region = var.region
}

# Create a KMS key for encryption
resource "aws_kms_key" "example" {
  description             = "Example Database Encryption Key"
  deletion_window_in_days = 10
  is_enabled               = true
}

# Create an IAM role for the database instance
resource "aws_iam_role" "database_instance" {
  name        = "DatabaseInstanceRole"
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
      },
    ]
  })
}

# Create an IAM policy for the database instance
resource "aws_iam_policy" "database_instance" {
  name        = "DatabaseInstancePolicy"
  description = "IAM policy for the database instance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:StartDBInstance",
          "rds:StopDBInstance",
          "rds:DeleteDBInstance",
        ]
        Effect   = "Allow"
        Resource = aws_db_instance.example.arn
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
        ]
        Effect   = "Allow"
        Resource = aws_kms_key.example.arn
      },
    ]
  })
}

# Attach the IAM policy to the role
resource "aws_iam_role_policy_attachment" "database_instance" {
  role       = aws_iam_role.database_instance.name
  policy_arn = aws_iam_policy.database_instance.arn
}

# Create a database instance with Secrets Manager for managed master passwords
resource "aws_db_instance" "example" {
  identifier           = "example-db"
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  username             = var.db_username
  password             = aws_secretsmanager_secret.example.version_1.SecretString
  parameter_group_name = "default.mysql5.7"
  vpc_security_group_ids = [aws_security_group.example.id]
  db_subnet_group_name = aws_db_subnet_group.example.name

  # Use the KMS key for encryption
  kms_key_id = aws_kms_key.example.key_id

  # Enable Secrets Manager for managed master passwords
  skip_final_snapshot = true
}

# Create a security group with restricted ingress rules
resource "aws_security_group" "example" {
  name        = "DatabaseSecurityGroup"
  description = "Security group for the database instance"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

# Create a Secrets Manager secret for the managed master password
resource "aws_secretsmanager_secret" "example" {
  name        = "DatabaseMasterPassword"
  description = "Managed master password for the database instance"

  # Use a KMS key to encrypt the secret
  kms_key_id = aws_kms_key.example.key_id
}

# Create a version of the Secrets Manager secret with the managed master password
resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = var.db_password
}