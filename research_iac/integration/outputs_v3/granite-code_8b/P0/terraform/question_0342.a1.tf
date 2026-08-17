provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "subnet-a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-a"
  }
}

resource "aws_subnet" "subnet-b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "subnet-b"
  }
}

resource "aws_security_group" "db_sg" {
  name   = "db_sg"
  description = "Security group for the database"
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
    Name = "db_sg"
  }
}

resource "aws_db_instance" "postgres" {
  identifier           = "postgres-db"
  engine               = "postgres"
  engine_version       = "15.3"
  instance_class       = "db.t4g.micro"
  storage_type         = "gp2"
  multi_az             = false
  publicly_accessible  = true
  skip_final_snapshot  = true
  backup_retention_period = 0

  subnets = [
    aws_subnet.subnet-a.id,
    aws_subnet.subnet-b.id,
  ]

  security_groups = [
    aws_security_group.db_sg.id,
  ]

  tags = {
    Name = "postgres-db"
  }
}

output "database_endpoint" {
  value = aws_db_instance.postgres.endpoint
}