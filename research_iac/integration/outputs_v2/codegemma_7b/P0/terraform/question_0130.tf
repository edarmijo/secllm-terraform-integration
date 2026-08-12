provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_instance" "webserver1" {
  ami           = "ami-0b4c4a4b4b4b4b4b4b"
  instance_type = "t2.micro"
  subnet_id      = aws_subnet.private_subnet.id

  provisioner "local-exec" {
    command = "sudo yum -y install nginx"
  }
}

resource "aws_instance" "webserver2" {
  ami           = "ami-0b4c4a4b4b4b4b4b4b"
  instance_type = "t2.micro"
  subnet_id      = aws_subnet.private_subnet.id

  provisioner "local-exec" {
    command = "sudo yum -y install nginx"
  }
}

resource "aws_efs" "shared_storage" {
  provisioner "local-exec" {
    command = "sudo yum -y install aws-cli"
  }

  provisioner "local-exec" {
    command = "aws efs create-file-system --creation-token 'my-file-system'"
  }
}

resource "aws_efs_mount_target" "webserver1_mount" {
  file_system_id = aws_efs.shared_storage.file_system_id
  subnet_id      = aws_subnet.private_subnet.id
}

resource "aws_efs_mount_target" "webserver2_mount" {
  file_system_id = aws_efs.shared_storage.file_system_id
  subnet_id      = aws_subnet.private_subnet.id
}