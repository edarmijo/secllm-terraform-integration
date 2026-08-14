provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_egress_only_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

resource "aws_vpc_ipv6_cidr_block_association" "example" {
  vpc_id       = aws_vpc.example.id
  ipv6_cidr_block = "2001:db8:1234:1::/64"
}