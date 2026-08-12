provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_disk" "disk" {
  name = "my-disk"
  size = 20
  availability_zone = "us-east-1a"
}

resource "aws_lightsail_instance" "instance" {
  name = "my-instance"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"

  resources {
    disk_ids = [aws_lightsail_disk.disk.id]
  }
}