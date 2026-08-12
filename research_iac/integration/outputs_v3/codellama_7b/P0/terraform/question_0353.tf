provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example" {
  cidr_block        = "10.0.1.0/24"
  vpc_id            = aws_vpc.example.id
  availability_zone = "us-east-1a"
}

resource "aws_security_group" "example" {
  name        = "example"
  description = "Example security group"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_iam_role" "example" {
  name               = "example"
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

resource "aws_secretsmanager_secret" "example" {
  name = "example-mysql-password"
}

resource "aws_rds_cluster" "example" {
  cluster_identifier      = "example"
  engine                  = "aurora-mysql"
  database_name           = "example"
  master_username         = "admin"
  master_password         = aws_secretsmanager_secret.example.arn
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.example.id]
  db_subnet_group_name    = aws_db_subnet_group.example.name
}

resource "aws_rds_cluster_instance" "example" {
  identifier           = "example-primary"
  cluster_identifier   = aws_rds_cluster.example.id
  instance_class       = "db.t3.medium"
  engine               = "aurora-mysql"
  db_parameter_group   = "default.aurora-mysql5.7"
  apply_immediately    = true
  auto_minor_version_upgrade = false
}

resource "aws_db_subnet_group" "example" {
  name       = "example"
  subnet_ids = [aws_subnet.example.id]
}