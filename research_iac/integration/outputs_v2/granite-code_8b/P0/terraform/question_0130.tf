# Configure the AWS provider
provider "aws" {
  region = var.region
}

# Create a VPC with private subnets
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Environment = "dev"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.${count.index + 1}/24"
  availability_zone = var.availability_zones[count.index]

  tags = {
    Environment = "dev"
  }
}

# Create an EFS file system for shared storage
resource "aws_efs_file_system" "example" {
  creation_token   = "example"
  encrypted        = true
  kms_key_id       = aws_kms_key.example.id

  tags = {
    Environment = "dev"
  }
}

# Create two EC2 instances in the private subnets, mounting the EFS file system for shared storage
resource "aws_instance" "example" {
  count               = 2
  ami                 = data.aws_ami.ubuntu.id
  instance_type       = "t2.micro"
  availability_zone   = var.availability_zones[count.index]
  subnet_id            = element(aws_subnet.private.*.id, count.index)
  associate_public_ip_address = false
  key_name             = aws_key_pair.example.key_name
  security_groups      = [aws_security_group.example.id]

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
    encrypted   = true
  }

  tags = {
    Environment = "dev"
  }
}

# Mount the EFS file system on the EC2 instances
resource "aws_efs_mount_target" "example" {
  count           = length(aws_subnet.private.id)
  file_system_id  = aws_efs_file_system.example.id
  subnet_id       = element(aws_subnet.private.*.id, count.index)
  security_groups = [aws_security_group.example.id]
}