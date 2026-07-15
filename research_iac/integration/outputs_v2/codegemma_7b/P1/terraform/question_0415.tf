provider "aws" {
  region = "us-east-1"
}

resource "aws_rds_instance" "example" {
  identifier = "my-rds-instance"
  engine = "mysql"
  engine_version = "8.0.27"
  instance_class = "db.t3.medium"
  storage_type = "io1"
  allocated_storage = 20
  username = var.db_username
  password = var.db_password
  vpc_security_group_ids = [aws_security_group.example.id]
}

resource "aws_security_group" "example" {
  name = "my-security-group"

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "db_username" {
  type = string
  sensitive = true
}

variable "db_password" {
  type = string
  sensitive = true
}