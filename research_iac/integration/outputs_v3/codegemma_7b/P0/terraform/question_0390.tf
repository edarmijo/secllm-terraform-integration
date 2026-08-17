provider "aws" {
  region = "us-east-1"
}

resource "aws_lb" "test-lb-tf" {
  name               = "test-lb-tf"
  internal           = false
  enable_deletion_protection = true

  security_groups = [aws_security_group.test-sg.id]

  subnets = [aws_subnet.test-subnet.id]
}

resource "aws_security_group" "test-sg" {
  name        = "test-sg"
  description = "Security group for test-lb-tf"

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

resource "aws_subnet" "test-subnet" {
  vpc_id        = aws_vpc.test-vpc.id
  cidr_block    = "192.168.0.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_vpc" "test-vpc" {
  cidr_block = "192.168.0.0/16"
}