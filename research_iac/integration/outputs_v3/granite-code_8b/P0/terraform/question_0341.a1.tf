provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "subnet1" {
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "subnet2"
  }
}

resource "aws_security_group" "database_sg" {
  name = "database_sg"
  description = "Security group for database access"
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "database_sg"
  }
}

resource "aws_db_instance" "postgres_rds" {
  identifier = "postgres_rds"
  engine = "postgres"
  engine_version = "15.3"
  instance_class = "db.t3.small"
  storage_type = "gp2"
  storage_encrypted = true
  multi_az = true
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  security_groups = [aws_security_group.database_sg.id]
  publicly_accessible = true
  tags = {
    Name = "postgres_rds"
  }
}

output "database_endpoint" {
  value = aws_db_instance.postgres_rds.endpoint
}