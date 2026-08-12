provider "aws" {
  region = "us-east-1"
}

resource "aws_rds_instance" "postgres_instance" {
  engine               = "postgres"
  engine_version       = "15.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 5
  storage_type         = "gp2"
  db_name              = "airbyte"
  username             = var.rds_username
  password             = var.rds_password
  publicly_accessible  = true
  vpc_security_group_ids = [aws_security_group.postgres_sg.id]
  subnet_group_name    = aws_db_subnet_group.postgres_subnet_group.name
}

resource "aws_security_group" "postgres_sg" {
  name        = "postgres_sg"
  description = "Security group for PostgreSQL instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_db_subnet_group" "postgres_subnet_group" {
  name        = "postgres_subnet_group"
  description = "Subnet group for PostgreSQL instance"
  subnet_ids  = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

resource "aws_subnet" "subnet1" {
  cidr_block      = "10.0.1.0/24"
  vpc_id          = aws_vpc.main.id
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "subnet2" {
  cidr_block      = "10.0.2.0/24"
  vpc_id          = aws_vpc.main.id
  availability_zone = "us-east-1b"
}