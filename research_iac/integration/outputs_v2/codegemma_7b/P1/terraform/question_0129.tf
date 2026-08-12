provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "private1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_subnet" "private2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
}

resource "aws_security_group" "web_servers" {
  name = "web-servers"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "application_servers" {
  name = "application-servers"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }
}

resource "aws_security_group" "database" {
  name = "database"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["10.0.3.0/24"]
  }
}

resource "aws_instance" "web_server" {
  ami = "ami-0b4444444444444444"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public.id
  security_groups = [aws_security_group.web_servers.id]
}

resource "aws_instance" "application_server" {
  ami = "ami-0a4444444444444444"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private1.id
  security_groups = [aws_security_group.application_servers.id]
}

resource "aws_rds_instance" "database" {
  engine = "postgres"
  engine_version = "14.2"
  instance_class = "db.t2.micro"
  allocated_storage = 20
  subnet_id = aws_subnet.private2.id
  security_groups = [aws_security_group.database.id]
}