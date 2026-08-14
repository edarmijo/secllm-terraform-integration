resource "aws_efs_file_system" "example" {
  creation_token = "example"

  backup_policy {
    status = "ENABLED"
  }
}