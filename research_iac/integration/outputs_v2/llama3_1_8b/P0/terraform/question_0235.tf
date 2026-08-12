provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "EgressOnlyVPC"
    Environment = "dev"
  }
}

resource "aws_egress_only_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_egress_only_internet_gateway.example.id
  }
}

resource "aws_main_route_table_association" "example" {
  vpc_id     = aws_vpc.example.id
  route_table_id = aws_route_table.example.id
}