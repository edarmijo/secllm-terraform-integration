provider "aws" {
  region = "us-east-1"
}

resource "aws_efs_file_system" "example" {
  creation_token = "my-efs"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = true
  kms_key_id = "alias/aws/efs"

  tags = {
    Name = "My EFS"
  }
}

resource "aws_efs_file_system_policy" "example" {
  file_system_id = aws_efs_file_system.example.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:root"
      },
      "Action": "elasticfilesystem:*",
      "Resource": "arn:aws:elasticfilesystem:us-east-1:123456789012:file-system/fs-12345678"
    }
  ]
}
POLICY
}