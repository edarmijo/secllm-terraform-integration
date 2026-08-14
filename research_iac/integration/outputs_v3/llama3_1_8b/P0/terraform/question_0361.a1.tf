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

resource "null_resource" "ssh_key" {
  provisioner "local-exec" {
    command = "cp ~/.ssh/id_rsa.pub /tmp/id_rsa.pub"
  }
}

resource "aws_lightsails_key_pair_attachment" "example" {
  name       = aws_lightsail_instance.example.name
  public_key = file("/tmp/id_rsa.pub")
}

resource "aws_lightsail_instance" "example" {
  name              = "example-lightsail-instance"
  blueprint_id      = "conventionally-configured-linux-os"
  bundle_id         = "nano_2_0"
  availability_zone = "us-east-1a"

  depends_on = [aws_lightsails_key_pair_attachment.example]
}