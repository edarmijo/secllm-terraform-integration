provider "aws" {
  region = "us-east-1"
}

variable "db_password" {
  description = "The password for the database user"
}

variable "db_username" {
  description = "The username for the database user"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "subnet1" {
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "subnet2"
  }
}

resource "aws_security_group" "db_sg" {
  name_prefix = "db_sg"
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "db_sg"
  }
}

resource "aws_db_instance" "postgres" {
  engine = "postgres"
  engine_version = "15.3"
  instance_class = "db.t3.small"
  name = "postgres-db"
  username = var.db_username
  password = var.db_password
  storage_encrypted = true
  storage_type = "gp2"
  multi_az = true
  subnets = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  security_groups = [aws_security_group.db_sg.id]
  publicly_accessible = false
  backup_retention_period = 7
  skip_final_snapshot_before_deletion = true
}

output "db_endpoint" {
  value = aws_db_instance.postgres.endpoint
}