provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_instance" "dualstack_instance" {
  name = "dualstack-instance"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"

  dualstack_ip = true

  tags = {
    Name = "Dualstack Instance"
  }
}