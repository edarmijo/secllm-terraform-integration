provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Environment = "dev"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"

  availability_zone = "us-east-1a"

  tags = {
    Environment = "dev"
    Type        = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"

  availability_zone = "us-east-1b"

  tags = {
    Environment = "dev"
    Type        = "private"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Environment = "dev"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    gateway_id = aws_internet_gateway.example.id
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Environment = "dev"
  }
}

resource "aws_security_group" "database" {
  name   = "database-sg"
  description = "Security group for MySQL and PostgreSQL databases"
  ingress {
    from_port   = 3306 # MySQL default port
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access from any IP address
  }

  ingress {
    from_port   = 5432 # PostgreSQL default port
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access from any IP address
  }

  tags = {
    Environment = "dev"
  }
}

resource "aws_db_subnet_group" "example" {
  name       = "database-subnet-group"
  subnet_ids = [aws_subnet.public.id, aws_subnet.private.id]

  tags = {
    Environment = "dev"
  }
}