provider "aws" {
  region = "us-east-1"
}

resource "aws_efs_file_system" "efs" {
  encrypted = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_efs_backup_policy" "backup_policy" {
  file_system_id = aws_efs_file_system.efs.file_system_id
  status          = "ENABLED"
}