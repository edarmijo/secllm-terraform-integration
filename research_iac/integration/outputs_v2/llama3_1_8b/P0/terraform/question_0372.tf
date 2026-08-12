provider "aws" {
  region = "us-west-2"
}

resource "aws_lightsail_disk" "example" {
  name              = "example-disk"
  size_in_gb        = 20
  source_from       = "ami-0c94855ba95c71c99"
  snapshot_name     = ""
  encrypted         = false
  is_a_static_ip    = false
}

resource "aws_lightsail_instance" "example" {
  name              = "example-instance"
  blueprint_id      = "ubuntu_18_04_64_bits"
  source_disk_name  = aws_lightsail_disk.example.name
}