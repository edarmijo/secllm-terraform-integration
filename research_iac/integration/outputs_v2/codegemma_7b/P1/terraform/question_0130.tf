provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_instance" "webserver1" {
  ami           = "ami-0b4a4a4a4a4a4a4a4a"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.id

  provisioner "file" {
    content = "Hello, world!"
    destination = "/mnt/efs/index.html"
  }
}

resource "aws_instance" "webserver2" {
  ami           = "ami-0b4a4a4a4a4a4a4a4a"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.id

  provisioner "file" {
    content = "Hello, world!"
    destination = "/mnt/efs/index.html"
  }
}

resource "aws_efs" "shared_storage" {
  provisioner "local-exec" {
    command = "aws efs create-file-system --creation-token \"my-file-system\""
  }
}

resource "aws_efs_mount_target" "webserver1_mount" {
  file_system_id = aws_efs.shared_storage.id
  subnet_id     = aws_subnet.private.id
  security_groups = [aws_security_group.webserver_sg.id]
}

resource "aws_efs_mount_target" "webserver2_mount" {
  file_system_id = aws_efs.shared_storage.id
  subnet_id     = aws_subnet.private.id
  security_groups = [aws_security_group.webserver_sg.id]
}

resource "aws_security_group" "webserver_sg" {
  name = "webserver-sg"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}