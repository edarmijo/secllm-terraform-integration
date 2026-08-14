provider "aws" {
  region = "us-east-1"
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "Example Internet Gateway"
  }
}

resource "aws_egress_only_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "Example Egress-Only Internet Gateway"
  }
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "::/0"
    gateway_id = aws_internet_gateway.example.id
  }

  tags = {
    Name = "Example Route Table"
  }
}

resource "aws_route_table_association" "example" {
  subnet_id      = aws_subnet.example.id
  route_table_id = aws_route_table.example.id
}

resource "aws_security_group" "example" {
  name        = "Example Security Group"
  description = "Allow inbound traffic on port 80 and all outbound traffic"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["::/0"]
    ipv6_cidr_blocks = ["2001:db8::/32"]
  }
}