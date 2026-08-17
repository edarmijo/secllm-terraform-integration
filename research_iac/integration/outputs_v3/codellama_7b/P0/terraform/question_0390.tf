provider "aws" {
  region = "us-east-1"
}

resource "aws_alb" "test-lb-tf" {
  name               = "test-lb-tf"
  internal           = false
  deletion_protection = true

  security_groups = [
    aws_security_group.test-sg-tf.id,
  ]

  subnets = [
    aws_subnet.test-subnet-tf.id,
  ]
}

resource "aws_security_group" "test-sg-tf" {
  name        = "test-sg-tf"
  description = "Test security group for ALB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "test-subnet-tf" {
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}