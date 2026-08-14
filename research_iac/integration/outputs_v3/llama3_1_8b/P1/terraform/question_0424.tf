provider "aws" {
  region = var.region
}

data "aws_region" "current" {}

resource "aws_iam_role" "efs_backup" {
  name        = "${var.name}-efs-backup-role"
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

resource "aws_iam_role_policy" "efs_backup" {
  name   = "${var.name}-efs-backup-policy"
  role   = aws_iam_role.efs_backup.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "backup:CreateBackupVault",
          "backup:GetBackupVaultAccessPolicy",
          "backup:StartBackupJob",
          "backup:ListBackupJobs",
          "backup:DescribeBackupVaults",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "efs_access" {
  name   = "${var.name}-efs-access-policy"
  role   = aws_iam_role.efs_backup.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateMountTarget",
          "ec2:DescribeMountTargets",
          "ec2:DeleteMountTarget",
        ]
        Effect = "Allow"
        Resource = aws_efs_file_system.efs.arn
      },
    ]
  })
}

resource "aws_iam_role_policy" "efs_backup_access" {
  name   = "${var.name}-efs-backup-access-policy"
  role   = aws_iam_role.efs_backup.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "backup:GetBackupVaultAccessPolicy",
          "backup:DescribeBackupVaults",
        ]
        Effect = "Allow"
        Resource = aws_iam_role.efs_backup.arn
      },
    ]
  })
}

resource "aws_efs_file_system" "efs" {
  name           = var.name
  performance_mode = "generalPurpose"

  tags = {
    Name = var.name
  }
}

resource "aws_efs_mount_target" "efs" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = var.subnet_id

  vpc_security_group_ids = [var.security_group_id]
}

resource "aws_backup_vault" "vault" {
  name        = "${var.name}-backup-vault"
  kms_key_arn = var.kms_key_arn
}

resource "aws_backup_plan" "plan" {
  name       = "${var.name}-backup-plan"
  backup_vault_name = aws_backup_vault.vault.id

  rule {
    rule_name         = "${var.name}-rule"
    target_backup_vault_name = aws_backup_vault.vault.id
    lifecycle {
      delete_after_days = 30
    }
  }

  rule {
    rule_name         = "${var.name}-efs-rule"
    target_backup_vault_name = aws_backup_vault.vault.id

    lifecycle {
      cold_storage_after_days = 30
      delete_after_days       = 60
    }
  }
}

resource "aws_iam_role_policy_attachment" "backup_attach" {
  role       = aws_iam_role.efs_backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonBackupServiceRolePolicyForBackup"
}