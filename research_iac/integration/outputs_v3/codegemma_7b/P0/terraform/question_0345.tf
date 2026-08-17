provider "aws" {
  region = "us-east-1"
}

resource "aws_rds_db_instance" "mysql_instance" {
  engine = "mysql"
  engine_version = "8.0.28"
  instance_class = "db.t3.medium"
  allocated_storage = 20
  storage_type = "gp2"
  publicly_accessible = true
  skip_final_snapshot = false

  username = "admin"
  password = var.password

  tags = {
    Name = "MySQL Database Instance"
  }
}

variable "password" {
  type = string
  sensitive = true
}