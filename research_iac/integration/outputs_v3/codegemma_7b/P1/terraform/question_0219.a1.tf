provider "aws" {
  region = var.region
}

resource "aws_db_instance" "my_mysql_instance" {
  engine = "MySQL"
  engine_version = "8.0"
  instance_class = "t2.micro"
  allocated_storage = 20
  username = var.db_username
  password = var.db_password
  db_name = var.db_name
  vpc_security_group_ids = [aws_security_group.my_security_group.id]
}

resource "aws_security_group" "my_security_group" {
  name = "my-mysql-security-group"

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["<your_allowed_ip_address>/32"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "region" {
  type = string
  default = "us-east-1"
}

variable "db_username" {
  type = string
  sensitive = true
  default = "your_default_username"
}

variable "db_password" {
  type = string
  sensitive = true
  default = "your_default_password"
}

variable "db_name" {
  type = string
  default = "your_default_database"
}