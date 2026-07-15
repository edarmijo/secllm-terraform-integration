provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "subnet2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_security_group" "database" {
  name = "database-security-group"

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
  }
}

resource "aws_rds_cluster" "database" {
  engine = "postgres"
  engine_version = "15.3"
  instance_class = "db.t4g.micro"
  allocated_storage = 200
  storage_type = "gp2"
  publicly_accessible = true
  vpc_security_group_ids = [aws_security_group.database.id]
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "database"
  }
}

output "database_endpoint" {
  value = aws_rds_cluster.database.endpoint
}