provider "aws" {
  region = "us-west-2"
}

resource "aws_security_group" "test-lb-sg" {
  name        = "test-lb-sg"
  description = "Security group for test-lb"
  vpc_id      = aws_vpc.test-vpc.id

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

resource "aws_security_group" "test-lb-sg-internal" {
  name        = "test-lb-sg-internal"
  description = "Security group for test-lb internal"
  vpc_id      = aws_vpc.test-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "test-vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "test-lb-subnet-1" {
  vpc_id            = aws_vpc.test-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "test-lb-subnet-2" {
  vpc_id            = aws_vpc.test-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
}

resource "aws_alb" "test-lb" {
  name            = "test-lb-tf"
  subnets         = [aws_subnet.test-lb-subnet-1.id, aws_subnet.test-lb-subnet-2.id]
  security_groups = [aws_security_group.test-lb-sg.id]
  internal        = false
  deletion_protection = true

  tags = {
    Name = "test-lb-tf"
  }
}