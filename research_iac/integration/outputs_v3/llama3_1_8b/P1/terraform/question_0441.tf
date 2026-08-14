provider "aws" {
  region = var.region
}

data "aws_region" "current" {}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_egress_only_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

resource "aws_security_group" "example" {
  name        = "allow-ipv6-outbound"
  description = "Allow IPv6 outbound traffic"
  vpc_id      = aws_vpc.example.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group_rule" "example" {
  type              = "egress"
  security_group_id = aws_security_group.example.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["::/0"]
}

resource "aws_instance" "example" {
  ami           = var.ami
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.example.id]
  ipv6_address_count = 1
  ipv6_address_cidr_block = "2001:db8:1234::/56"

  provisioner "local-exec" {
    command = <<EOF
      echo ${aws_instance.example.ipv6_address} > ip_address.txt
EOF
  }
}

resource "aws_secretsmanager_secret" "example" {
  name = "egress-only-igw-secret"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode({
    egress_only_internet_gateway_id = aws_egress_only_internet_gateway.example.id
  })
}