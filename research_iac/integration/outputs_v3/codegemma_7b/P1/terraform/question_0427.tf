provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet1" {
  vpc_id = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "public_subnet2" {
  vpc_id = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_internet_gateway" "example" {
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table_association" "example" {
  route_table_id = aws_route_table.example.id
  subnet_id = aws_subnet.public_subnet1.id
}

resource "aws_route_table_association" "example2" {
  route_table_id = aws_route_table.example.id
  subnet_id = aws_subnet.public_subnet2.id
}

resource "aws_route" "example" {
  route_table_id = aws_route_table.example.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.example.id
}