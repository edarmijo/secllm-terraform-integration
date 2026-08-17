provider "aws" {
  region = "us-east-1"
}

resource "aws_efs_file_system" "efs" {
  # Remove the name attribute
  # name = "my-efs"

  encrypted = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "efs_access_role" {
  name = "efs-access-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "efs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "efs_system_policy" {
  name = "efs-system-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:DescribeFileSystems",
        "elasticfilesystem:DescribeMountTargets"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "efs_system_policy_attachment" {
  role       = aws_iam_role.efs_access_role.name
  policy_arn = aws_iam_policy.efs_system_policy.arn
}

resource "aws_efs_mount_target" "mount_target" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = "subnet-0123456789abcdef0"
  security_groups = ["sg-0123456789abcdef0"]

  depends_on = [aws_iam_role_policy_attachment.efs_system_policy_attachment]
}