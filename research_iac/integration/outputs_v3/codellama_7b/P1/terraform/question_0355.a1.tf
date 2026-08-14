provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS cluster"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_iam_role" "rds_proxy_role" {
  name               = "rds-proxy-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "rds_proxy_policy" {
  name   = "rds-proxy-policy"
  role   = aws_iam_role.rds_proxy_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "secretsmanager:GetSecretValue",
      "Effect": "Allow",
      "Resource": "${aws_secretsmanager_secret.rds_proxy_credentials.arn}"
    }
  ]
}
EOF
}

resource "aws_secretsmanager_secret" "rds_proxy_credentials" {
  name = "rds-proxy-credentials"
}

resource "aws_db_instance" "example" {
  identifier             = "example-rds-cluster"
  engine                 = "aurora-mysql"
  engine_version         = "5.7.mysql_aurora.2.03.1"
  instance_class         = "db.t3.medium"
  allocated_storage      = 20
  max_allocated_storage  = 100
  storage_encrypted      = true
  apply_immediately      = true
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.example.name
  parameter_group_name   = "default.aurora-mysql5.7"
  multi_az               = true
  iam_database_authentication_enabled = true
}

resource "aws_db_subnet_group" "example" {
  name       = "example-rds-cluster-subnet-group"
  subnet_ids = [aws_subnet.example.id]
}