provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "example-vpc"
  }
}

resource "aws_subnet" "public" {
  count = 3
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "example-public-subnet-${count.index + 1}"
  }
  # Add the missing argument "vpc_id"
  vpc_id = aws_vpc.example.id

  depends_on = [aws_vpc.example]
}

resource "aws_internet_gateway" "example" {
  tags = {
    Name = "example-internet-gateway"
  }

  depends_on = [aws_vpc.example]
}

resource "aws_route_table" "public" {
  count = 3
  cidr_block = "0.0.0.0/0"
  tags = {
    Name = "example-public-route-table-${count.index + 1}"
  }
  # Add the missing argument "vpc_id"
  vpc_id = aws_vpc.example.id

  depends_on = [aws_vpc.example]
}

resource "aws_route" "public" {
  count = 3
  route_table_id = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.example.id

  depends_on = [aws_internet_gateway.example, aws_route_table.public]
}

resource "aws_route_table_association" "public" {
  count = 3
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id

  depends_on = [aws_route_table.public, aws_subnet.public]
}