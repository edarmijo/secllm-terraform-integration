provider "aws" {
  region = var.region
}

resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Environment = "dev"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }

  tags = {
    Name = "example-rt"
  }
}

resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"

  availability_zone = var.availability_zones[0]

  tags = {
    Name = "example-pub1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"

  availability_zone = var.availability_zones[1]

  tags = {
    Name = "example-pub2"
  }
}

resource "aws_subnet" "public3" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.3.0/24"

  availability_zone = var.availability_zones[2]

  tags = {
    Name = "example-pub3"
  }
}