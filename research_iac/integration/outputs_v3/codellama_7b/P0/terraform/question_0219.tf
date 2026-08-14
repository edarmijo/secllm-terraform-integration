provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "my_mysql_instance" {
  engine               = "mysql"
  allocated_storage    = 20
  instance_class       = "db.t3.micro"
  name                 = "my_mysql_database"
  username             = "my_user"
  password             = "my_password"
  parameter_group_name = "default.mysql5.7"
}