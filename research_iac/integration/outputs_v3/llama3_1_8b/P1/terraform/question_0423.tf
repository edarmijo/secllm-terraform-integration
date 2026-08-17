provider "aws" {
  region = "us-west-2"
}

# Create a secret for the EFS file system
resource "aws_secretsmanager_secret" "efs_secret" {
  name = "efs-file-system-secret"
}

resource "aws_secretsmanager_secret_version" "efs_secret_version" {
  secret_id     = aws_secretsmanager_secret.efs_secret.id
  secret_string = jsonencode({
    "AccessKey" = "your-access-key"
    "SecretKey" = "your-secret-key"
  })
}

# Create an IAM role for the EFS file system
resource "aws_iam_role" "efs_role" {
  name        = "efs-role"
  description = "EFS role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "fsd.kms.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "efs_policy" {
  name   = "efs-policy"
  role   = aws_iam_role.efs_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Effect = "Allow"
        Resource = aws_secretsmanager_secret.efs_secret.arn
      }
    ]
  })
}

# Create an IAM instance profile for the EFS file system
resource "aws_iam_instance_profile" "efs_instance_profile" {
  name = "efs-instance-profile"
  role = aws_iam_role.efs_role.name
}

# Create an EFS file system
resource "aws_efs_file_system" "efs" {
  name = "my-efs-file-system"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true
  kms_key_id       = aws_secretsmanager_secret.efs_secret.arn
}

# Create an EFS mount target
resource "aws_efs_mount_target" "efs_mount_target" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = "subnet-12345678"
  security_groups = [aws_security_group.efs_security_group.id]
}

# Create a security group for the EFS file system
resource "aws_security_group" "efs_security_group" {
  name        = "efs-security-group"
  description = "EFS security group"

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

# Create a system policy for the EFS file system
resource "aws_efs_file_system_policy" "efs_policy" {
  file_system_id = aws_efs_file_system.efs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowRootAccess"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        }
        Action = [
          "efs:Mount"
        ]
        Resource = aws_efs_file_system.efs.arn
      }
    ]
  })
}