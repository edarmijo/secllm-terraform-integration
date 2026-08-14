provider "aws" {
  region = "us-east-1"
}

resource "aws_efs_file_system" "efs" {
  name = "my-efs"
  encrypted = true

  lifecycle {
    automatic_backup = true
  }
}