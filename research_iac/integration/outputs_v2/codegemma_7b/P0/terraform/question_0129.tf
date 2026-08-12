provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "private2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1c"
}

resource "aws_instance" "web_server" {
  ami = "ami-0b4444444444444444"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public.id
}

resource "aws_instance" "app_server" {
  ami = "ami-0a4444444444444444"
  instance_type = "t2.medium"
  subnet_id = aws_subnet.private1.id
}

resource "aws_rds_instance" "database" {
  engine = "mysql"
  engine_version = "8.0.27"
  instance_class = "db.t2.micro"
  allocated_storage = 20
  username = "admin"
  password = "password"
  subnet_id = aws_subnet.private2.id
}