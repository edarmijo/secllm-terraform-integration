provider "aws" {
  region = "us-east-1"
}

resource "aws_rds_instance" "example" {
  engine = "mysql"
  engine_version = "8.0.27"
  instance_class = "db.t3.medium"
  allocated_storage = 20
  storage_type = "io1"
  name = "example-db"
  username = "admin"
  password = "strongpassword"
}