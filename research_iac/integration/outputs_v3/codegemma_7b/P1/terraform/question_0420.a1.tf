provider "aws" {
  region = "us-east-1"
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

resource "aws_db_instance" "mysql_instance" {
  engine = "MySQL"
  engine_version = "8.0"
  instance_class = "db.t2.micro"
  allocated_storage = 20
  username = var.db_username
  password = var.db_password
  db_name = "my_database"
}

resource "aws_db_snapshot" "mysql_snapshot" {
  db_instance_identifier = aws_db_instance.mysql_instance.id
  snapshot_identifier = "my_mysql_snapshot"
}