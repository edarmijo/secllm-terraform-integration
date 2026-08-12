provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "Example VPC"
  }
}

resource "aws_subnet" "public" {
  cidr_block        = "10.0.1.0/24"
  vpc_id            = aws_vpc.example.id
  availability_zone = "us-east-1a"
  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private1" {
  cidr_block        = "10.0.2.0/24"
  vpc_id            = aws_vpc.example.id
  availability_zone = "us-east-1b"
  tags = {
    Name = "Private Subnet 1"
  }
}

resource "aws_subnet" "private2" {
  cidr_block        = "10.0.3.0/24"
  vpc_id            = aws_vpc.example.id
  availability_zone = "us-east-1c"
  tags = {
    Name = "Private Subnet 2"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.example.id
}

resource "aws_security_group" "webservers" {
  name        = "Web Servers"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "appservers" {
  name        = "App Servers"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_security_group" "rds" {
  name        = "RDS"
  description = "Allow MySQL traffic"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_instance" "webservers" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.webservers.id]
}

resource "aws_instance" "appservers" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.appservers.id]
}

resource "aws_rds_instance" "example" {
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  allocated_storage    = 10
  vpc_security_group_ids = [aws_security_group.rds.id]
}