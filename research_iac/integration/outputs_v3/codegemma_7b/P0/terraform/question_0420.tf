provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "my_mysql_instance" {
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t2.micro"
  allocated_storage = 20
  name = "my_mysql_instance"
}

resource "aws_db_snapshot" "my_mysql_snapshot" {
  db_instance_identifier = aws_db_instance.my_mysql_instance.id
  snapshot_identifier = "my_mysql_snapshot"
}