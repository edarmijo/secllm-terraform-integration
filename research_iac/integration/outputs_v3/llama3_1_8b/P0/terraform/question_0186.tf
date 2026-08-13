provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "latest_amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.latest_amazon_linux_2.id
  instance_type = "t3.medium"

  vpc_security_group_ids = [aws_security_group.example.id]

  root_block_device {
    volume_type = "gp2"
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sda1"
    volume_size           = 30
    delete_on_termination = true
  }
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow inbound traffic on port 22"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}