provider "aws" {
  region = var.region
}

resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Environment = "production"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"

  availability_zone = var.availability_zones[0]

  tags = {
    Environment = "production"
    Type        = "public"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"

  availability_zone = var.availability_zones[0]

  tags = {
    Environment = "production"
    Type        = "private"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.3.0/24"

  availability_zone = var.availability_zones[1]

  tags = {
    Environment = "production"
    Type        = "private"
  }
}