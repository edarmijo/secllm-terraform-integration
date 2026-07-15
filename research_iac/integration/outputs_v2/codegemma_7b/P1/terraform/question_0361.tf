provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_instance" "example" {
  name = "my-lightsail-instance"
  blueprint_id = "amazon_linux_2"
  availability_zone = "us-east-1a"
  key_name = "my-key-pair"
  tags = {
    Name = "My Lightsail Instance"
  }
}