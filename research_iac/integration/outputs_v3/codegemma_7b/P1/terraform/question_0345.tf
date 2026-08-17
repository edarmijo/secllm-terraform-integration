provider "aws" {
  region = "us-east-1"
}

variable "db_name" {
  type = string
  default = "my_database"
}

variable "db_username" {
  type = string
  default = "db_user"
}

variable "db_password" {
  type = string
  sensitive = true
  default = "randomly_generated_password"
}

resource "aws_rds_db_instance" "mysql_instance" {
  engine = "MySQL"
  engine_version = "8.0"
  instance_class = "db.t2.micro"
  allocated_storage = 20
  storage_type = "gp2"
  db_name = var.db_name
  username = var.db_username
  password = var.db_password
  skip_final_snapshot = false
  publicly_accessible = true

  tags = {
    Name = "My MySQL Database"
  }
}

resource "aws_security_group_rule" "allow_mysql_access" {
  type = "ingress"
  from_port = 3306
  to_port = 3306
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mysql_security_group.id
}

resource "aws_security_group" "mysql_security_group" {
  name = "mysql-security-group"
  description = "Security group for MySQL database"
}