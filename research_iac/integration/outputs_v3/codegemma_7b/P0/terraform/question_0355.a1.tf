provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "security_group" {
  name = "rds-security-group"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "rds_proxy_role" {
  name = "rds-proxy-role"

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

resource "aws_secretsmanager_secret" "rds_credentials" {
  name = "rds-credentials"
  secret_string = "username:password"
}

resource "aws_rds_cluster" "rds_cluster" {
  engine = "aurora-mysql"
  engine_version = "5.7.mysql_aurora.2.10.0"
  cluster_identifier = "my-aurora-cluster"
  vpc_security_group_ids = [aws_security_group.security_group.id]
  subnet_ids = [aws_subnet.subnet.id]
  master_username = "username"
  master_password = aws_secretsmanager_secret.rds_credentials.secret_string
  allocated_storage = 20
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
}

resource "aws_db_proxy" "rds_proxy" {
  name = "my-rds-proxy"
  engine_family = "mysql"
  auth_types = ["SECRETS_MANAGER"]
  secrets_manager_auth_name = aws_secretsmanager_secret.rds_credentials.name
  vpc_id = aws_vpc.vpc.id
  db_cluster_identifier = aws_rds_cluster.rds_cluster.id
  role_arn = aws_iam_role.rds_proxy_role.arn
}