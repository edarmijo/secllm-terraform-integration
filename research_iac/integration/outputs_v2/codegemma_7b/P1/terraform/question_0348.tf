provider "aws" {
  region = "us-east-1"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = ["subnet-12345678", "subnet-98765432"]
}

resource "aws_db_instance" "db_instance" {
  name                = "postgres-instance"
  allocated_storage   = 50
  engine              = "postgres"
  engine_version       = "14.2"
  instance_class      = "db.t3.medium"
  max_allocated_storage = 50
  maintenance_window = "mon:00:00-mon:03:00"
  vpc_security_group_ids = ["sg-12345678"]
  subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  username = "postgres"
  password = var.db_password
}

variable "db_password" {
  type = string
  sensitive = true
}