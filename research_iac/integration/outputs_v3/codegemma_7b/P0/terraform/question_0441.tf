provider "aws" {
  region = "us-east-1"
}

resource "aws_internet_gateway" "egw" {
  name = "egress-only-igw"
}

resource "aws_vpc_gateway_attachment" "egw_attach" {
  vpc_id = "vpc-1234567890abcdef01"
  internet_gateway_id = aws_internet_gateway.egw.id
}

resource "aws_route_table" "egw_route_table" {
  vpc_id = "vpc-1234567890abcdef01"
}

resource "aws_route" "egw_route" {
  route_table_id = aws_route_table.egw_route_table.id
  destination_cidr_block = "::/0"
  gateway_id = aws_internet_gateway.egw.id
}