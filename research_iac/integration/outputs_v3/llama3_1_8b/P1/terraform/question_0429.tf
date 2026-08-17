provider "aws" {
  region = "us-west-2"
}

data "aws_secretsmanager_secret" "vpc_cidr" {
  name = "vpc-cidr"
}

data "aws_secretsmanager_secret_version" "vpc_cidr" {
  secret_id = data.aws_secretsmanager_secret.vpc_cidr.id
}

locals {
  vpc_cidr = jsondecode(data.aws_secretsmanager_secret_version.vpc_cidr.secret_string).vpc_cidr
}

resource "aws_vpc" "example" {
  cidr_block = local.vpc_cidr
  tags = {
    Name = "example-vpc"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "example-igw"
  }
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "example-rtb"
  }
}

resource "aws_route" "example" {
  route_table_id = aws_route_table.example.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.example.id
}

resource "aws_route_table_association" "example" {
  count = 3
  route_table_id = aws_route_table.example.id
  subnet_id = aws_subnet.example[count.index].id
}

resource "aws_subnet" "example" {
  count = 3
  vpc_id = aws_vpc.example.id
  cidr_block = cidrsubnet(local.vpc_cidr, 8, count.index)
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "example-subnet-${count.index + 1}"
  }
}

resource "aws_security_group" "example" {
  vpc_id = aws_vpc.example.id
  name = "example-sg"
  description = "Allow inbound traffic on port 22"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}