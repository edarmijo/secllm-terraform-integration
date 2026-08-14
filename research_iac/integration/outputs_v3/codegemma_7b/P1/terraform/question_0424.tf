provider "aws" {
  region = "us-east-1"
}

resource "aws_efs_file_system" "efs" {
  encrypted = true
  provisioners = ["local-exec"]

  provisioner "local-exec" {
    command = "aws efs create-backup --file-system-id ${aws_efs_file_system.efs.file_system_id}"
  }
}

resource "aws_iam_role" "backup_role" {
  name = "backup_role"

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

resource "aws_iam_policy" "backup_policy" {
  name = "backup_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "efs:CreateBackup",
        "efs:DescribeBackups",
        "efs:DeleteBackup"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = aws_iam_policy.backup_policy.arn
}

resource "aws_efs_backup_policy" "backup_policy" {
  file_system_id = aws_efs_file_system.efs.file_system_id
  status          = "ENABLED"
}