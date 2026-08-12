provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Example VPC"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.example.id
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "Private Subnet ${count.index}"
  }
}

resource "aws_efs_file_system" "example" {
  creation_token = "example-fs"

  tags = {
    Name = "Example EFS File System"
  }
}

resource "aws_efs_mount_target" "private" {
  count           = length(aws_subnet.private)
  file_system_id  = aws_efs_file_system.example.id
  subnet_id       = element(aws_subnet.private.*.id, count.index)
  security_groups = [aws_security_group.example.id]
}

resource "aws_instance" "example" {
  count         = 2
  ami           = data.aws_ami.latest-amazon-linux-2.id
  instance_type = "t3.micro"
  subnet_id     = element(aws_subnet.private.*.id, count.index)
  vpc_security_group_ids = [aws_security_group.example.id]

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "Example EC2 Instance ${count.index}"
  }
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "latest-amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm*"]
  }
}