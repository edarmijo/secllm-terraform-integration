provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_disk" "disk" {
  name = "my-disk"
  size = 20
}

resource "aws_lightsail_instance" "instance" {
  name = "my-instance"
  instance_type = "t2.micro"

  network_interface {
    device_index = 0
    subnet_id = aws_subnet.subnet.id
  }
}

resource "aws_lightsail_disk_attachment" "attachment" {
  disk_name = aws_lightsail_disk.disk.name
  instance_name = aws_lightsail_instance.instance.name
}