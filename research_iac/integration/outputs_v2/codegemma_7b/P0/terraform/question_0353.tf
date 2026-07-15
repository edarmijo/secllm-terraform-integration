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
  name = "aurora-security-group"
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

resource "aws_secrets_manager_secret" "db_credentials" {
  name = "aurora-db-credentials"
  secret_string = jsonencode({
    username = "admin"
    password = "strongpassword"
  })
}

resource "aws_rds_cluster" "aurora_cluster" {
  engine = "aurora"
  engine_version = "5.7.mysql_aurora.2"
  cluster_identifier = "my-aurora-cluster"
  vpc_security_group_ids = [aws_security_group.security_group.id]
  subnet_ids = [aws_subnet.subnet.id]

  database_name = "mydatabase"
  master_username = aws_secrets_manager_secret.db_credentials.username
  master_password = aws_secrets_manager_secret.db_credentials.password

  proxy {
    engine = "mysql"
    auth_type = "SECRET"
    secrets_manager_auth_name = aws_secrets_manager_secret.db_credentials.name
  }
}