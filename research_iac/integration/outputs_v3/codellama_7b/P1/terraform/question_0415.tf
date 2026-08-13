provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "example" {
  engine               = "mysql"
  allocated_storage    = 20
  instance_class       = "db.t3.micro"
  storage_type         = "io1"
  iops                 = 1000
  name                 = "example-database"
  username             = "admin"
  password             = var.rds_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}