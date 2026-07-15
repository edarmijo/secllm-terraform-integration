provider "aws" {
  region = "us-east-1"
}

resource "aws_efs_file_system" "example" {
  creation_token   = "my-efs"
  encrypted        = true
  kms_key_id       = aws_kms_key.example.arn
  lifecycle_policy = jsonencode({
    transition_to_ia = "AFTER_14_DAYS"
  })
}

resource "aws_kms_key" "example" {
  description             = "EFS KMS key"
  deletion_window_in_days = 7
}