provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "example" {
  engine                    = "postgres"
  instance_class            = "db.t3.micro"
  allocated_storage         = 50
  max_allocated_storage     = 50
  maintenance_window        = "mon:00:00-mon:03:00"
  backup_retention_period   = 1
  storage_type              = "gp2"
  vpc_security_group_ids    = [aws_security_group.example.id]
  subnet_id                 = aws_subnet.example.id
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow inbound traffic for PostgreSQL"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "example-vpc"
  }
}

resource "aws_subnet" "example" {
  cidr_block        = "10.0.1.0/24"
  vpc_id            = aws_vpc.example.id
  availability_zone = "us-east-1a"
}