provider "aws" {
  region = "us-west-2"
}

resource "aws_dax_subnet_group" "custom_dax_subnet_group" {
  name       = "custom-dax-subnet-group"
  subnet_ids = [aws_subnet.dax_subnet.id]
}

resource "aws_subnet" "dax_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "dax-subnet"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}