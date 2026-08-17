provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "mysql" {
  engine           = "mysql"
  engine_version   = "5.7"
  instance_class   = "db.t2.small"
  name             = "my-mysql-instance"
  username         = "my-user"
  password         = "my-password"
  skip_final_snapshot = true
}

resource "aws_db_snapshot" "mysql_snapshot" {
  db_instance_identifier = aws_db_instance.mysql.id
  db_snapshot_identifier  = "my-mysql-snapshot"
}