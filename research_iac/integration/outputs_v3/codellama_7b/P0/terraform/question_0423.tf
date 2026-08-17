provider "aws" {
  region = "us-east-1"
}

resource "aws_efs_file_system" "example" {
  creation_token = "my-efs"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = true
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  tags = {
    Name = "My EFS"
  }
}

resource "aws_iam_role" "example" {
  name = "MyEFSRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "example" {
  name = "MyEFSRolePolicy"
  role = aws_iam_role.example.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "elasticfilesystem:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}