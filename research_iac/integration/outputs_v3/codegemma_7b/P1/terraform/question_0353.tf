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
  name = "rds-proxy-security-group"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_rds_cluster" "cluster" {
  engine = "aurora-mysql"
  engine_version = "5.7.mysql_aurora.2"
  cluster_identifier = "my-aurora-cluster"
  vpc_security_group_ids = [aws_security_group.security_group.id]
  subnet_ids = [aws_subnet.subnet.id]

  database_name = "mydatabase"
  username = "myusername"
  password = var.password
}

resource "aws_secrets_manager_secret" "secret" {
  name = "rds-credentials"
  secret_string = jsonencode({
    username = "myusername"
    password = var.password
  })
}

resource "aws_rds_proxy" "proxy" {
  name = "my-rds-proxy"
  engine_family = "mysql"
  auth {
    type = "secretsmanager"
    secret_arn = aws_secrets_manager_secret.secret.arn
  }
  vpc_security_group_ids = [aws_security_group.security_group.id]
  subnet_ids = [aws_subnet.subnet.id]
}