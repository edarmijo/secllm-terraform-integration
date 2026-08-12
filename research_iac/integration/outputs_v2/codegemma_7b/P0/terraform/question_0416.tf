provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "restore_db_role" {
  name = "restore-db-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "restore_db_role_policy" {
  role       = aws_iam_role.restore_db_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_db_instance" "restored_db" {
  identifier = "restored-db"
  engine       = "mysql"
  engine_version = "8.0.28"
  allocated_storage = 20
  instance_class = "db.t3.medium"

  restore_type = "s3"
  restore_source_engine_type = "mysql"
  restore_source_s3_bucket = "your-s3-bucket-name"
  restore_source_s3_prefix = "your-s3-prefix"

  tags = {
    Name = "Restored Database"
  }

  depends_on = [aws_iam_role_policy_attachment.restore_db_role_policy]
}