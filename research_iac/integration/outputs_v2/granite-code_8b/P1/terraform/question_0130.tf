provider "aws" {
  region = var.region
}

resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Environment = "dev"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"

  availability_zone = var.availability_zone

  tags = {
    Environment = "dev"
    Type        = "private"
  }
}

resource "aws_efs_file_system" "example" {
  creation_token = "example"

  encrypted = true

  tags = {
    Environment = "dev"
  }
}

resource "aws_efs_mount_target" "example" {
  file_system_id  = aws_efs_file_system.example.id
  subnet_id       = aws_subnet.private.id
  security_groups = [aws_security_group.example.id]
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.latest_ubuntu.id
  instance_type = var.instance_type

  subnet_id      = aws_subnet.private.id
  security_groups = [
    aws_security_group.example.id,
    aws_security_group.ssh.id,
  ]

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }

  tags = {
    Environment = "dev"
    Name        = "example-instance"
  }
}