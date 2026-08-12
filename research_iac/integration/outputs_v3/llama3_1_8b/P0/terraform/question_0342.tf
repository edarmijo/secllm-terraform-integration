provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "Main VPC" }
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  tags              = { Name = "Subnet 1 (AZ A)" }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
  tags              = { Name = "Subnet 2 (AZ B)" }
}

resource "aws_security_group" "db_access" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "main_rds" {
  allocated_storage      = 200
  engine                 = "postgres"
  instance_class         = "db.t4g.micro"
  name                   = "mydatabase"
  username               = "myusername"
  password               = "mypassword"
  vpc_security_group_ids = [aws_security_group.db_access.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  publicly_accessible    = true
  storage_type           = "gp2"

  tags = {
    Name = "Main RDS Instance"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "main-rds-subnet-group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}