provider "aws" {
  region = "us-east-1"
}

variable "mysql_username" {
  type = string
}

variable "mysql_password" {
  type = string
}

resource "aws_db_instance" "my_mysql_instance" {
  engine                    = "mysql"
  engine_version            = "8.0.23"
  instance_class            = "db.t3.micro"
  allocated_storage         = 20
  storage_type              = "gp2"
  name                      = "my_database"
  username                  = var.mysql_username
  password                  = var.mysql_password
  parameter_group_name      = "default.mysql8.0"
  db_subnet_group_name      = aws_db_subnet_group.my_mysql_subnet_group.name
  vpc_security_group_ids    = [aws_security_group.my_mysql_sg.id]
  backup_retention_period   = 10
  skip_final_snapshot       = true
}

resource "aws_db_subnet_group" "my_mysql_subnet_group" {
  name       = "my_mysql_subnet_group"
  subnet_ids = [aws_subnet.my_mysql_subnet1.id, aws_subnet.my_mysql_subnet2.id]
}

resource "aws_security_group" "my_mysql_sg" {
  name        = "my_mysql_sg"
  description = "Security group for my MySQL instance"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_subnet" "my_mysql_subnet1" {
  cidr_block      = "10.0.1.0/24"
  vpc_id          = aws_vpc.my_vpc.id
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "my_mysql_subnet2" {
  cidr_block      = "10.0.2.0/24"
  vpc_id          = aws_vpc.my_vpc.id
  availability_zone = "us-east-1b"
}

resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}