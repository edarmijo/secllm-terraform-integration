provider "aws" {
  region = var.region
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
}

resource "aws_lightsail_instance" "db_instance" {
  name = "db-instance"
  instance_type = "t2.micro"
  availability_zone = var.region
}

resource "aws_lightsail_database" "db" {
  name = var.db_name
  engine = "mysql"
  username = var.db_user
  password = var.db_password
  database_name = var.db_name
  allocated_storage = 20
  instance_name = aws_lightsail_instance.db_instance.name
}