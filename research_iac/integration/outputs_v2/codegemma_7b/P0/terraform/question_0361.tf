provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_instance" "example" {
  name = "my-lightsail-instance"
  blueprint_id = "amazon_linux_2_x86_64"
}