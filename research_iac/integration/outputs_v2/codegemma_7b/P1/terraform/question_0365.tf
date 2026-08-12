provider "aws" {
  region = "us-east-1"
}

variable "ssh_key_name" {
  type = string
}

resource "aws_lightsail_instance" "example" {
  name = "my-lightsail-instance"
  instance_type = "t2.micro"
  key_name = var.ssh_key_name
}