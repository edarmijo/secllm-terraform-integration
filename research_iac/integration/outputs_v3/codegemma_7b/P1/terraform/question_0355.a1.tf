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
    cidr_blocks = ["10.0.0.0/16"]
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
  secret_string = "username=admin;password=password;"
}

resource "aws_rds_cluster" "rds_cluster" {
  engine = "aurora"
  engine_version = "5.7.mysql_aurora.2"
  cluster_identifier = "my-aurora-cluster"
  vpc_security_group_ids = [aws_security_group.security_group.id]
  subnet_ids = [aws_subnet.subnet.id]

  database_name = "mydatabase"
  master_username = "admin"
  master_password = aws_secretsmanager_secret.rds_credentials.secret_string

  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
}

resource "aws_db_proxy" "rds_proxy" {
  name = "my-rds-proxy"
  engine_family = "mysql"
  auth {
    type = "SECRETS_MANAGER"
    secret_arn = aws_secretsmanager_secret.rds_credentials.arn
  }
  vpc_id = aws_vpc.vpc.id
  db_cluster_parameter_group_name = "default.aurora-mysql5.7"
  idle_client_timeout = 300
  max_connections = 100
}