provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "efs_lifecycle_policy_exec" {
  name        = "EFSLifecyclePolicyExecRole"
  description = "Execution role for EFS lifecycle policy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "efs_lifecycle_policy_exec" {
  name        = "EFSLifecyclePolicyExecPolicy"
  description = "Execution policy for EFS lifecycle policy"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "efs:DescribeFileSystem",
          "efs:DescribeMountTarget",
          "efs:UpdateFileSystem"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "efs_lifecycle_policy_exec_attach" {
  role       = aws_iam_role.efs_lifecycle_policy_exec.name
  policy_arn = aws_iam_policy.efs_lifecycle_policy_exec.arn
}

resource "aws_efs_file_system" "example" {
  creation_token   = "examplefs"
  performance_mode = "generalPurpose"

  lifecycle_policy {
    transition_to_iops_mode {
      snapshot_delete_policy {
        delete_after_days = 30
      }
    }
  }

  tags = {
    Name = "example-efs"
  }
}

resource "aws_iam_role" "efs_lifecycle_policy_admin" {
  name        = "EFSLifecyclePolicyAdminRole"
  description = "Administration role for EFS lifecycle policy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "efs_lifecycle_policy_admin" {
  name        = "EFSLifecyclePolicyAdminPolicy"
  description = "Administration policy for EFS lifecycle policy"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "efs:DescribeFileSystem",
          "efs:DescribeMountTarget",
          "efs:UpdateFileSystem"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "efs_lifecycle_policy_admin_attach" {
  role       = aws_iam_role.efs_lifecycle_policy_admin.name
  policy_arn = aws_iam_policy.efs_lifecycle_policy_admin.arn
}