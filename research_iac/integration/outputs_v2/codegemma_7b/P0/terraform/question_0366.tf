provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_instance" "db_instance" {
  name = "my-database"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"

  resource_type = "mysql"
  database_name = "my_database"
  username = "admin"
  password = "strongpassword"
}