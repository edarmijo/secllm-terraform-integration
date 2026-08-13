provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_app" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_subnet" "private_db" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
}

resource "aws_security_group" "webserver" {
  name = "webserver-sg"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "appserver" {
  name = "appserver-sg"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "database" {
  name = "database-sg"
  vpc_id = aws_vpc.main.id
}