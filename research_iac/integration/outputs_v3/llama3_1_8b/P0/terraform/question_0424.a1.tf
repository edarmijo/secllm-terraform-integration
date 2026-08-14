provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "efs_backup_role" {
  name        = "efs-backup-role"
  description = "Role for EFS backup"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "efs_backup_policy" {
  name   = "efs-backup-policy"
  role   = aws_iam_role.efs_backup_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "backup:CreateBackupVault",
          "backup:GetBackupVault",
          "backup:ListBackupVaults",
          "backup:StartBackupJob",
          "backup:DescribeBackupJobs",
          "backup:DeleteBackupVault",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_efs_file_system" "example" {
  creation_token   = "examplefs"
  performance_mode = "generalPurpose"

  tags = {
    Name = "example-efs"
  }
}

resource "aws_backup_vault" "example" {
  name = "example-vault"
}

resource "aws_backup_selection" "example" {
  iam_role_arn = aws_iam_role.efs_backup_role.arn
  name         = "example-selection"

  selection_tag {
    key   = "Name"
    value = "example-efs"
  }
}