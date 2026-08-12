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
  vocab_id = aws_vpc.example.id

  route {
    gateway_id = aws_internet_gateway.example.id
    destination_cidr_block = "0.0.0.0/0"
  }

  tags = {
    Environment = "dev"
  }
}

resource "aws_db_subnet_group" "example" {
  name       = "example-db-subnet-group"
  subnet_ids = [aws_subnet.public.id, aws_subnet.private.id]

  tags = {
    Environment = "dev"
  }
}

resource "aws_security_group" "mysql" {
  name   = "mysql-sg"
  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "dev"
  }
}

resource "aws_db_instance" "mysql" {
  identifier           = "example-mysql"
  engine               = "mysql"
  engine_version       = "5.7.21"
  instance_class       = "db.t2.micro"
  name                 = "example-mysql"
  username             = "admin"
  password             = "password"
  skip_final_snapshot = true
  subnet_ids           = [aws_subnet.public.id, aws_subnet.private.id]
  security_groups      = [aws_security_group.mysql.id]

  tags = {
    Environment = "dev"
  }
}