provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "example" {
  engine               = "aurora-mysql"
  engine_version       = "5.7.mysql_aurora.2.03.2"
  instance_class       = "db.t3.medium"
  allocated_storage    = 10
  storage_type         = "gp2"
  name                 = "example"
  username             = "admin"
  password             = var.password
  db_subnet_group_name = aws_db_subnet_group.example.name
  vpc_security_group_ids = [aws_security_group.example.id]
}

resource "aws_db_subnet_group" "example" {
  name       = "example"
  subnet_ids = aws_subnet.example.*.id
}

resource "aws_subnet" "example" {
  cidr_block = "10.0.0.0/16"
  vpc_id     = aws_vpc.example.id
}

resource "aws_security_group" "example" {
  name        = "example"
  description = "Allow inbound traffic to the Aurora MySQL cluster"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}