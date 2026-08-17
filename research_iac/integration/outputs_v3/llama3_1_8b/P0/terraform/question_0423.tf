provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "efs_role" {
  name        = "efs-role"
  description = "EFS role for system policy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "fsd.kms.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "efs_policy" {
  name        = "efs-policy"
  description = "EFS policy for system policy"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:CreateGrant",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:ListGrants",
          "kms:RevokeGrant",
          "kms:ScheduleKeyDeletion",
          "kms:UpdateAlias",
          "kms:UpdateKeyDescription",
          "kms:UpdateKeyPolicy",
          "kms:UpdateKeyUsage",
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncryptFrom",
          "kms:ReEncryptTo",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "kms:CreateKey",
          "kms:DescribeKey",
          "kms:EnableKey",
          "kms:DisableKey",
          "kms:ScheduleKeyDeletion",
          "kms:UpdateKeyDescription",
          "kms:UpdateKeyPolicy",
          "kms:UpdateKeyUsage",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "efs_attach" {
  role       = aws_iam_role.efs_role.name
  policy_arn = aws_iam_policy.efs_policy.arn
}

resource "aws_efs_file_system" "example" {
  creation_token   = "examplefs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name = "examplefs"
  }
}

resource "aws_efs_mount_target" "example" {
  file_system_id = aws_efs_file_system.example.id
  subnet_id      = "subnet-12345678"
  security_groups = [aws_security_group.example.id]
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow inbound traffic on port 22"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}