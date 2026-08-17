provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

variable "name" {
  type        = string
  description = "Name for the EFS lifecycle policy"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for the EFS security group"
}

variable "region" {
  type        = string
  description = "AWS region"
}

resource "aws_iam_role" "efs_lifecycle_policy" {
  name        = "${var.name}-efs-lifecycle-policy"
  description = "EFS lifecycle policy role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "efs_lifecycle_policy" {
  name        = "${var.name}-efs-lifecycle-policy"
  description = "EFS lifecycle policy"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:CreateTags",
          "elasticfilesystem:DeleteTags",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "efs_lifecycle_policy_attach" {
  role       = aws_iam_role.efs_lifecycle_policy.name
  policy_arn = aws_iam_policy.efs_lifecycle_policy.arn
}

resource "aws_efs_file_system" "example" {
  creation_token   = var.name
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

resource "aws_security_group" "example" {
  name        = "${var.name}-efs-sg"
  description = "EFS security group"

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }
}

resource "aws_iam_instance_profile" "example" {
  name        = "${var.name}-efs-instance-profile"
  description = "EFS instance profile"

  role = aws_iam_role.efs_lifecycle_policy.name
}