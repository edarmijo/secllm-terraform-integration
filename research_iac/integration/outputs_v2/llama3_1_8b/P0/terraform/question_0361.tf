provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_instance" "example" {
  name              = "example-lightsail-instance"
  blueprint_id      = "conventionally-configured-linux-os"
  bundle_id         = "nano_2_0"
  availability_zone = "us-east-1a"

  depends_on = [aws_lightsail_key_pair.example]
}

resource "aws_lightsail_key_pair" "example" {
  name       = "example-lightsail-key-pair"
  public_key = file("~/.ssh/id_rsa.pub")
}