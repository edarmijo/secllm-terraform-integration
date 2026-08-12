provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "example-subnet"
  }
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow inbound traffic on PostgreSQL port"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "example" {
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "13.4"
  instance_class        = "db.t2.micro"
  name                   = "example-db"
  username               = "admin"
  password               = "password"
  vpc_security_group_ids = [aws_security_group.example.id]
  db_subnet_group_name   = aws_db_subnet_group.example.name
  skip_final_snapshot    = true

  maintenance_window = "mon:00:00-mon:03:00"

  max_allocated_storage = 50
}

resource "aws_db_subnet_group" "example" {
  name       = "example-db-subnet-group"
  subnet_ids = [aws_subnet.example.id]
}