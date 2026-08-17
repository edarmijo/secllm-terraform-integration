resource "aws_lb" "test-lb-tf" {
  name               = "test-lb-tf"
  internal           = false

  security_groups = [
    aws_security_group.test-lb-sg.id,
  ]

  subnets = [
    aws_subnet.test-lb-subnet-1.id,
    aws_subnet.test-lb-subnet-2.id,
  ]
}

resource "aws_security_group" "test-lb-sg" {
  name        = "test-lb-sg"
  description = "Security group for the test load balancer"
  vpc_id      = aws_vpc.test-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "test-lb-subnet-1" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.test-vpc.id
}

resource "aws_subnet" "test-lb-subnet-2" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = aws_vpc.test-vpc.id
}

resource "aws_vpc" "test-vpc" {
  cidr_block = "10.0.0.0/16"
}