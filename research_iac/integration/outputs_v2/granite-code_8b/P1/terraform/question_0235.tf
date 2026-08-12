# Create a new VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "example-vpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "example" {
  tags = {
    Name = "example-igw"
  }
}

# Attach the Internet Gateway to the VPC
resource "aws_egress_only_internet_gateway" "example" {
  internet_gateway_id = aws_internet_gateway.example.id
 vgw_id               = aws_vpc.example.id

  tags = {
    Name = "example-eigw"
  }
}