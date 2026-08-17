# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "example-vpc"
  }
}

# Create a route table
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "example-route-table"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "example" {
  tags = {
    Name = "example-internet-gateway"
  }
}

# Attach the internet gateway to the VPC
resource "aws_vpc_internet_gateway_attachment" "example" {
  vpc_id      = aws_vpc.example.id
  internet_gateway_id = aws_internet_gateway.example.id
}

# Create a public subnet
resource "aws_subnet" "public_subnet_1" {
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "example-public-subnet-1"
  }
}

# Create another public subnet
resource "aws_subnet" "public_subnet_2" {
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "example-public-subnet-2"
  }
}

# Create a route table association for the first public subnet
resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.example.id
}

# Create a route table association for the second public subnet
resource "aws_route_table_association" "public_subnet_2_assoc" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.example.id
}