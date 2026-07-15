provider "aws" {
  region = "us-east-1"
}

resource "aws_efs" "example" {
  file_system_name = "example"
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}