provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_instance" "dualstack_instance" {
  name = "dualstack-instance"
  availability_zone = "us-east-1a"
  blueprint_id = "amazon_linux_2_x64_dual_stack"
  key_name = "your_key_pair_name"
  tags = {
    Name = "Dualstack Instance"
  }
}

resource "aws_lightsail_static_ip" "dualstack_static_ip" {
  name = "dualstack-static-ip"
  instance_name = aws_lightsail_instance.dualstack_instance.name
}