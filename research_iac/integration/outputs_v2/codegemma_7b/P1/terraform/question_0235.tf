provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "Example VPC"
  }
}

resource "aws_internet_gateway" "example" {
  tags = {
    Name = "Example Internet Gateway"
  }
}

resource "aws_vpc_gateway_attachment" "example" {
  vpc_id = aws_vpc.example.id
  internet_gateway_id = aws_internet_gateway.example.id
}

resource "aws_egress_only_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}