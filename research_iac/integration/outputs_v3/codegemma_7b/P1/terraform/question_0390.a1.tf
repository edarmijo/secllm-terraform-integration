provider "aws" {
  region = "us-east-1"
}

resource "aws_lb" "test-lb-tf" {
  name               = "test-lb-tf"
  internal           = false

  security_groups = [aws_security_group.test-sg.id]

  subnets = [
    aws_subnet.test-subnet-1.id,
    aws_subnet.test-subnet-2.id,
  ]

  enable_deletion_protection = true
}