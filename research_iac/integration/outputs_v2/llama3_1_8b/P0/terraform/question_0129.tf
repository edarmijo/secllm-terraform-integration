provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private_app" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "Private App Subnet"
  }
}

resource "aws_subnet" "private_db" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "Private DB Subnet"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "Internet Gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web_servers" {
  name        = "Web Servers SG"
  description = "Allow inbound traffic on port 80 and 443"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_servers" {
  name        = "App Servers SG"
  description = "Allow inbound traffic on port 22 and 3306"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }
}

resource "aws_security_group" "db_servers" {
  name        = "DB Servers SG"
  description = "Allow inbound traffic on port 3306"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.3.0/24"]
  }
}

resource "aws_instance" "web_servers" {
  ami           = "ami-abc123"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_servers.id]
  subnet_id       = aws_subnet.public.id

  tags = {
    Name = "Web Servers"
  }
}

resource "aws_instance" "app_servers" {
  ami           = "ami-abc123"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.app_servers.id]
  subnet_id       = aws_subnet.private_app.id

  tags = {
    Name = "App Servers"
  }
}

resource "aws_db_instance" "db_servers" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "mydatabase"
  username             = "admin"
  password             = "password"
  vpc_security_group_ids = [aws_security_group.db_servers.id]
  subnet_id            = aws_subnet.private_db.id

  tags = {
    Name = "DB Servers"
  }
}