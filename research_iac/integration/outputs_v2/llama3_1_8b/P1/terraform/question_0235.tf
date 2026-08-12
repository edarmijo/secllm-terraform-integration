provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret_version" "vpc_cidr" {
  secret_id = aws_secretsmanager_secret.vpc_cidr.id
}

resource "aws_secretsmanager_secret" "vpc_cidr" {
  name = "vpc-cidr"
}

resource "aws_vpc" "example" {
  cidr_block = data.aws_secretsmanager_secret_version.vpc_cidr.secret_string

  tags = {
    Name        = "Example VPC"
    Environment = var.environment
  }
}

resource "aws_egress_only_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow inbound traffic on port 22 and 443"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_cidr_block}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "egress_only_internet_gateway" {
  type              = "egress"
  security_group_id = aws_security_group.example.id
  vpc_id            = aws_vpc.example.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["${aws_egress_only_internet_gateway.example.ip_prefix}/32"]
}