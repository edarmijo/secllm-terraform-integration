provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "example-vpc"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example-igw"
  }
}

resource "aws_vpc_attachment" "example" {
  subnet_id         = aws_subnet.example.id
  internet_gateway_id = aws_internet_gateway.example.id
}