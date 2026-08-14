resource "aws_efs" "example" {
  file_system_id = "fs-0123456789abcdef0"
  automatic_backup {
    day          = 7
    hour         = 23
    minute       = 50
  }
}