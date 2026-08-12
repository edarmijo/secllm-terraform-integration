provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_disk" "example" {
  name              = "example-disk"
  size_in_gb        = 20
  availability_zone = "us-east-1a"
}

resource "aws_lightsail_instance" "example" {
  name                    = "example-instance"
  availability_zone       = "us-east-1a"
  blueprint_id            = "amazon_linux_2"
  bundle_id               = "micro_2_0"
  user_data               = <<EOF
#!/bin/bash
yum update -y
yum install -y nginx
systemctl start nginx
systemctl enable nginx
EOF
  disk {
    name = aws_lightsail_disk.example.name
    size_in_gb = aws_lightsail_disk.example.size_in_gb
    availability_zone = aws_lightsail_disk.example.availability_zone
  }
}