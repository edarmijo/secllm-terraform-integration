resource "aws_efs_file_system" "example" {
  creation_token = "example"

  lifecycle {
    prevent_destroy = false
  }
}