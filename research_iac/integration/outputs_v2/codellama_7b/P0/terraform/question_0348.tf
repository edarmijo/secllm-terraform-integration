provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "example" {
  engine                    = "postgres"
  engine_version            = "13.4"
  instance_class             = "db.t3.medium"
  allocated_storage         = 5
  max_allocated_storage     = 50
  maintenance_window        = "mon:00:00-mon:03:00"
  vpc_security_group_ids    = [aws_security_group.example.id]
  db_subnet_group_name      = aws_db_subnet_group.example.name
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Example security group for the PostgreSQL database instance"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "example" {
  name        = "example-sg"
  description = "Example subnet group for the PostgreSQL database instance"
  subnet_ids  = [aws_subnet.example1.id, aws_subnet.example2.id]
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example1" {
  cidr_block        = "10.0.1.0/24"
  vpc_id            = aws_vpc.example.id
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "example2" {
  cidr_block        = "10.0.2.0/24"
  vpc_id            = aws_vpc.example.id
  availability_zone = "us-east-1b"
}