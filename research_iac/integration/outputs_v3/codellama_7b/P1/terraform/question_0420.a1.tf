provider "aws" {
  region = "us-east-1"
}

variable "db_password" {
  type = string
}

resource "aws_db_instance" "example" {
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp2"
  name                    = "example"
  username                = "root"
  password                = var.db_password
  parameter_group_name    = "default.mysql8.0"
  backup_retention_period = 1
  skip_final_snapshot     = true
}

resource "aws_db_snapshot" "example" {
  db_instance_identifier = aws_db_instance.example.id
  db_snapshot_identifier = "example-snapshot"
}