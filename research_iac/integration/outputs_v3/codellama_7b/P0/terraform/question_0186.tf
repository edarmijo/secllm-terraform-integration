provider "aws" {
  region = "us-east-1"
}

resource "aws_ami" "example" {
  name                = "example"
  description        = "Example AMI"
  architecture        = "x86_64"
  root_device_type    = "ebs"
  virtualization_type = "hvm"
  cpu_count           = 2
  cores_per_thread    = 2
}