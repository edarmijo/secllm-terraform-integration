provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.example.id
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index)
}

resource "aws_instance" "web_servers" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
}

resource "aws_instance" "application_servers" {
  ami           = "ami-12345678"
  instance_type = "t2.small"
  subnet_id     = aws_subnet.private[0].id
}

resource "aws_rds_instance" "example" {
  engine            = "mysql"
  instance_class    = "db.t2.micro"
  allocated_storage = 10
  storage_type      = "gp2"
  name              = "example"
  username          = "root"
  password          = "password"
  subnet_id         = aws_subnet.private[1].id
}