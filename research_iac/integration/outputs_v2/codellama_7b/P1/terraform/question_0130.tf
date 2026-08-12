provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_security_group" "private" {
  name        = "private-sg"
  description = "Security group for private subnets"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_instance" "ec2-instance" {
  count         = 2
  ami           = "ami-08d70e59c23aaa2ee" # Amazon Linux 2
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private[count.index].id
  vpc_security_group_ids = [aws_security_group.private.id]
}

resource "aws_efs_file_system" "shared-storage" {
  creation_token = "shared-storage"
}

resource "aws_efs_mount_target" "shared-storage" {
  count           = 2
  file_system_id  = aws_efs_file_system.shared-storage.id
  subnet_id       = aws_subnet.private[count.index].id
}

resource "aws_volume_attachment" "ec2-instance" {
  count          = 2
  device_name    = "/dev/xvdf"
  instance_id    = aws_instance.ec2-instance[count.index].id
  volume_id      = aws_efs_file_system.shared-storage.id
}