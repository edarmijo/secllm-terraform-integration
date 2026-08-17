provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_a" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.main.id
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "public_b" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = aws_vpc.main.id
  availability_zone = "us-east-1b"
}

resource "aws_db_subnet_group" "airbyte_connector_test" {
  name       = "airbyte_connector_test"
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "aws_security_group" "airbyte_connector_test" {
  name        = "airbyte_connector_test"
  description = "Allow inbound traffic for Airbyte connector test"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "airbyte_connector_test" {
  engine                    = "postgres"
  engine_version            = "15.0"
  instance_class            = "db.t3.medium"
  allocated_storage         = 20
  storage_type              = "gp2"
  name                      = "airbyte_connector_test"
  username                  = "admin"
  password                  = "your_password"
  backup_retention_period   = 0
  skip_final_snapshot       = true
  apply_immediately         = true
  vpc_security_group_ids    = [aws_security_group.airbyte_connector_test.id]
  db_subnet_group_name      = aws_db_subnet_group.airbyte_connector_test.name
  publicly_accessible       = true
}