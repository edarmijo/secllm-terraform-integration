provider "aws" {
  region = "us-east-1"
}

variable "vpc_name" {
  type = string
}

resource "aws_vpc" "dedicated_tenancy_vpc" {
  cidr_block = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "dedicated_tenancy_igw" {
  vpc_id = aws_vpc.dedicated_tenancy_vpc.id
}

resource "aws_route_table" "dedicated_tenancy_route_table" {
  vpc_id = aws_vpc.dedicated_tenancy_vpc.id

  route {
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dedicated_tenancy_igw.id
  }
}