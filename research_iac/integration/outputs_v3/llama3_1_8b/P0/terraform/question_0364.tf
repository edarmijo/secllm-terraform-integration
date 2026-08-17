provider "aws" {
  region = "us-west-2"
}

resource "aws_lightsail_instance" "example" {
  name              = "example-lightsail"
  blueprint_id      = "ubuntu_20_04"
  bundle_id         = "nano_1_0"
  availability_zone = "us-west-2a"
  ip_address_type   = "dualstack"
}

resource "aws_lightsail_static_ip_attachment" "example" {
  instance_name = aws_lightsail_instance.example.name
  static_ip_name = aws_lightsail_static_ip.example.name
}

resource "aws_lightsail_static_ip" "example" {
  name = "example-static-ip"
}

resource "aws_lightsail_key_pair" "example" {
  name       = "example-key-pair"
  public_key = file("~/.ssh/id_rsa.pub")
}