provider "aws" {
  region = "us-east-1"
}

resource "aws_efs_file_system" "example" {
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_efs_lifecycle_policy" "example" {
  file_system_id = aws_efs_file_system.example.file_system_id
  policy = jsonencode([
    {
      "TransitionToIA": "AFTER_30_DAYS",
      "TransitionToPrimaryStorageClass": "AFTER_365_DAYS"
    }
  ])
}