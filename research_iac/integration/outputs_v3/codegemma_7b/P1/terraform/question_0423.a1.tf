provider "aws" {
  region = "us-east-1"
}

resource "aws_efs_file_system" "system_efs" {
  name = "system-efs"
  encrypted = true
  throughput_mode = "bursting"
}

resource "aws_iam_role" "system_role" {
  name = "system-role"
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

resource "aws_iam_policy" "system_policy" {
  name = "system-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "efs:CreateMountTarget",
        "efs:DescribeFileSystems",
        "efs:MountFileSystem"
      ],
      "Resource": [
        aws_efs_file_system.system_efs.id
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "system_policy_attachment" {
  role = aws_iam_role.system_role.name
  policy_arn = aws_iam_policy.system_policy.arn
}

resource "aws_efs_mount_target" "system_mount_target" {
  file_system_id = aws_efs_file_system.system_efs.id
  target_file_system_id = aws_efs_file_system.system_efs.id
  subnet_id = "subnet-0123456789abcdef01"
  security_groups = ["sg-0123456789abcdef01"]
  iam_role = aws_iam_role.system_role.name
}