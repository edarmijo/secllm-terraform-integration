provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet1" {
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "subnet2" {
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "database" {
  name = "database"
  description = "Allow database access"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "database" {
  engine = "postgres"
  engine_version = "15.3"
  instance_class = "db.t2.micro"
  allocated_storage = 20
  identifier = "mydatabase"
  username = "myuser"
  password = "mypassword"
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name = aws_db_subnet_group.database.name
  publicly_accessible = true
}

resource "aws_db_subnet_group" "database" {
  name = "database"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

output "database_endpoint" {
  value = aws_db_instance.database.endpoint
}