provider "aws" {
  region = "us-east-1"
}

resource "aws_lb" "test-lb-tf" {
  name               = "test-lb-tf"
  internal           = false
  deletion_protection = true

  security_groups = [aws_security_group.test-sg.id]

  subnets = [
    aws_subnet.test-subnet-1.id,
    aws_subnet.test-subnet-2.id,
  ]
}

resource "aws_security_group" "test-sg" {
  name        = "test-sg"
  description = "Test security group"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "test-subnet-1" {
  vpc_id        = aws_vpc.test-vpc.id
  cidr_block    = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "test-subnet-2" {
  vpc_id        = aws_vpc.test-vpc.id
  cidr_block    = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_vpc" "test-vpc" {
  cidr_block = "10.0.0.0/16"
}