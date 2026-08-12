# Create the VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = var.name
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "my_internet_gateway" {
  tags = {
    Name = var.name
  }
}

# Attach the internet gateway to the VPC
resource "aws_vpc_internet_gateway_attachment" "my_internet_gateway_attachment" {
  vpc_id = aws_vpc.my_vpc.id

  internet_gateway_id = aws_internet_gateway.my_internet_gateway.id
}

# Create a route table for outbound internet access
resource "aws_route_table" "my_route_table" {
  tags = {
    Name = var.name
  }

  # Propagate routes to the main route table
  propagate_routes = [aws_route_table.main.id]

  # Add a route for the internet gateway
  route {
    cidr_block     = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.my_internet_gateway.id
  }
}