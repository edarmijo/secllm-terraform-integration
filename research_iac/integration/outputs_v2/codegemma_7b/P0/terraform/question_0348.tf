provider "aws" {
  region = "us-east-1"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]
}

resource "aws_db_instance" "db_instance" {
  engine            = "postgres"
  engine_version     = "14.2"
  instance_class    = "db.t3.medium"
  allocated_storage = 50
  max_allocated_storage = 50
  storage_type       = "gp2"
  vpc_security_group_ids = ["sg-12345678"]
  subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  maintenance_window = "mon:00:00-mon:03:00"
}