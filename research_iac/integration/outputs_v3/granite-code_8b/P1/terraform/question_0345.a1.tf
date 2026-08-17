provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "example" {
  engine           = "mysql"
  engine_version   = "5.7"
  instance_class   = "db.t2.small"
  name             = "example"
  username         = "exampleuser"
  password         = var.mysql_password
  skip_final_snapshot = false

  security_group_ids = [
    aws_security_group.example.id,
  ]

  backup_retention_period = "7"

  tags = {
    Environment = "dev"
  }
}

resource "aws_security_group" "example" {
  name_prefix = "example"
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "mysql_password" {
  description = "The password for the MySQL database"
}