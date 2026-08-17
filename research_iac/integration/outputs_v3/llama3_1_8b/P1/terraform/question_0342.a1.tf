variable "aws_region" {
  type        = string
  description = "AWS region"
}

provider "aws" {
  region = var.aws_region
}

# Create a new VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "main-vpc" }
}

# Create two subnets in different availability zones
resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.aws_region == "us-west-2" ? "us-west-2a" : "eu-central-1a"
  tags              = { Name = "subnet1" }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.aws_region == "us-west-2" ? "us-west-2b" : "eu-central-1b"
  tags              = { Name = "subnet2" }
}

# Create a security group for database access
resource "aws_security_group" "database_sg" {
  vpc_id = aws_vpc.main.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.subnet1.cidr_block, aws_subnet.subnet2.cidr_block]
  }
  tags       = { Name = "database-sg" }
}

# Create a new RDS instance with public accessibility
resource "aws_db_instance" "main" {
  allocated_storage      = 200
  engine                 = "postgres"
  engine_version         = "15.3"
  instance_class         = "db.t4g.micro"
  name                   = var.db_name
  username               = var.db_username
  password               = aws_secretsmanager_secret.db_password.secret_string
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  publicly_accessible    = true
  storage_type           = "gp2"
}

# Create a new DB subnet group
resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

# Store the database endpoint in a local variable
output "database_endpoint" {
  value = aws_db_instance.main.endpoint
}