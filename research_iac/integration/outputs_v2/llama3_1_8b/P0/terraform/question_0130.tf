provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  map_public_ip_on_launch = false

  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }
}

resource "aws_route_table_association" "private" {
  subnet_id     = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "example" {
  name        = "allow_ssh"
  description = "Allow inbound traffic on port 22"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_file_system" "example" {
  creation_token = "example"

  tags = {
    Name = "Example EFS File System"
  }
}

resource "aws_efs_mount_target" "example" {
  file_system_id = aws_efs_file_system.example.id
  subnet_id      = aws_subnet.private.id

  vpc_id = aws_vpc.example.id
}

resource "aws_instance" "linux2" {
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.example.id]
  subnet_id              = aws_subnet.private.id

  key_name               = "example-key"
  user_data              = <<-EOF
    #!/bin/bash
    echo "Hello, World!" > /mnt/efs/file.txt
  EOF

  root_block_device {
    volume_type           = "gp2"
    iops                  = 100
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sdh"
    volume_size           = 10
    delete_on_termination = true
  }
}

resource "aws_instance" "linux3" {
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.example.id]
  subnet_id              = aws_subnet.private.id

  key_name               = "example-key"
  user_data              = <<-EOF
    #!/bin/bash
    echo "Hello, World!" > /mnt/efs/file.txt
  EOF

  root_block_device {
    volume_type           = "gp2"
    iops                  = 100
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sdh"
    volume_size           = 10
    delete_on_termination = true
  }
}