provider "aws" {
  region = "us-east-1"
}

resource "aws_efs" "example" {
  creation_token   = "my-efs"
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name = "My EFS"
  }
}

resource "aws_efs_backup_policy" "example" {
  file_system_id = aws_efs.example.file_system_id
  backup_policy = jsonencode({
    BackupPolicy = {
      Status = "ENABLED"
    }
  })
}