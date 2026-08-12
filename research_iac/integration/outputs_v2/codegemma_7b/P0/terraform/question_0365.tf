provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_instance" "example" {
  name = "my-lightsail-instance"
  instance_type = "t2.micro"
  key_name = "my-ssh-key"
}