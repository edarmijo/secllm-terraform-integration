provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_instance" "example" {
  name              = "example"
  availability_zone = "us-east-1a"
  blueprint_id      = "amazon_linux_2"
  bundle_id         = "nano_2_0"
  key_pair_name     = aws_lightsail_key_pair.example.name
}

resource "aws_lightsail_key_pair" "example" {
  name      = "example"
  public_key = file("~/.ssh/id_rsa.pub")
}