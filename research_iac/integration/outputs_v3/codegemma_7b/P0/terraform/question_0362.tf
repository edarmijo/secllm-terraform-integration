provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_instance" "wordpress" {
  name = "wordpress-instance"
  blueprint_id = "wordpress"
  availability_zone = "us-east-1a"
  tags = {
    Name = "WordPress Instance"
  }
}