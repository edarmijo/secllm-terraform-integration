resource "aws_efs_file_system" "efs" {
  name = "my-efs"
  encrypted = true

  backup_policy {
    status = "enabled"
  }
}