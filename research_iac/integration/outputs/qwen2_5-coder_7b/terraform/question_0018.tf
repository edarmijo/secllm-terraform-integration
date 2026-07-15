provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "The AWS region to deploy resources in"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "webapp-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "webapp-igw"
  }
}

resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.region + "a"

  tags = {
    Name = "webapp-public-subnet-1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.region + "b"

  tags = {
    Name = "webapp-public-subnet-2"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "webapp-public-route-table"
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "webapp" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "webapp-sg"
  }
}

resource "aws_rds_instance" "db" {
  identifier            = "webapp-db"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t2.micro"
  username              = "admin"
  password              = var.db_password
  allocated_storage     = 20
  vpc_security_group_ids = [aws_security_group.webapp.id]
  subnet_group_name      = aws_db_subnet_group.subnet_group.name

  tags = {
    Name = "webapp-db"
  }
}

resource "aws_db_subnet_group" "subnet_group" {
  name       = "webapp-subnet-group"
  subnet_ids = [aws_subnet.public1.id, aws_subnet.public2.id]

  tags = {
    Name = "webapp-subnet-group"
  }
}