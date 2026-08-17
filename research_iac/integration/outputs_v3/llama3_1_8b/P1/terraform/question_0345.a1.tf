provider "aws" {
  region = "us-west-2"
}

# Create a secret to store the database password
resource "aws_secretsmanager_secret" "mysql_password" {
  name = "mysql-password"
}

# Create a secret value to store the database password
resource "aws_secretsmanager_secret_version" "mysql_password" {
  secret_id     = aws_secretsmanager_secret.mysql_password.id
  secret_string = jsonencode({"password": random_string.password.result})
}

# Create a VPC
resource "aws_vpc" "mysql_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a subnet
resource "aws_subnet" "mysql_subnet" {
  vpc_id            = aws_vpc.mysql_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

# Create a security group with public access
resource "aws_security_group" "mysql_sg" {
  name        = "mysql-sg"
  description = "Allow inbound traffic on port 3306"
  vpc_id      = aws_vpc.mysql_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an RDS instance
resource "aws_db_instance" "mysql_instance" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "mysql-instance"
  username             = "admin"
  password             = aws_secretsmanager_secret_version.mysql_password.secret_string
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  db_subnet_group_name = aws_db_subnet_group.mysql_subnet_group.name
  skip_final_snapshot  = false
}

# Create a DB subnet group
resource "aws_db_subnet_group" "mysql_subnet_group" {
  name       = "mysql-subnet-group"
  subnet_ids = [aws_subnet.mysql_subnet.id]
}

# Generate a random password
resource "random_string" "password" {
  length  = 16
  special = false
}