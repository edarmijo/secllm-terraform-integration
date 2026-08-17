provider "aws" {
  region = "us-east-1"
}

resource "aws_efs_file_system" "example" {
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}