provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "example" {
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  allocated_storage    = 20
  username            = "myuser"
  password            = "mypass"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot = true
}

resource "aws_db_snapshot" "example" {
  db_instance_identifier = aws_db_instance.example.id
  db_snapshot_identifier = "example-snapshot"
}