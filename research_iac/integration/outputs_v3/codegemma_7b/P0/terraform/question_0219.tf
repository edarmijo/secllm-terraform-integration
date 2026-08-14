provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "my_mysql_instance" {
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t2.micro"
  allocated_storage = 20
  username = "admin"
  password = "strongpassword"
  db_name = "my_database"
}