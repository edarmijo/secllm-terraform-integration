# Set up the variables
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "cidr_block" {
  description = "CIDRs for the VPC"
  type        = list(string)
}

variable "azs" {
  description = "Availability zones for the subnets"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDRs for the public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDRs for the private subnets"
  type        = list(string)
}

# Create the VPC
resource "aws_vpc" "example" {
  cidr_block           = var.cidr_block[0]
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# Create the internet gateway
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = var.vpc_name
  }
}

# Create the route table for outbound internet access
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    gateway_id = aws_internet_gateway.example.id
    destination_cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = var.vpc_name
  }
}

# Create the public subnets
resource "aws_subnet" "public" {
  count             = length(var.azs) * length(var.public_subnet_cidrs)
  availability_zone = element(var.azs, floor(count.index / length(var.public_subnet_cidrs)))
  cidr_block        = element(var.public_subnet_cidrs, count.index % length(var.public_subnet_cidrs))
  vpc_id            = aws_vpc.example.id

  tags = {
    Name = "${var.vpc_name}-public-${count.index + 1}"
  }
}

# Create the private subnets
resource "aws_subnet" "private" {
  count             = length(var.azs) * length(var.private_subnet_cidrs)
  availability_zone = element(var.azs, floor(count.index / length(var.private_subnet_cidrs)))
  cidr_block        = element(var.private_subnet_cidrs, count.index % length(var.private_subnet_cidrs))
  vpc_id            = aws_vpc.example.id

  tags = {
    Name = "${var.vpc_name}-private-${count.index + 1}"
  }
}