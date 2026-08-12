provider "aws" {
  region = var.region
}

data "aws_secretsmanager_secret" "ssh_key" {
  name = "lightsail-ssh-key"
}

resource "aws_secretsmanager_secret_version" "ssh_key" {
  secret_id     = data.aws_secretsmanager_secret.ssh_key.id
  secret_string = file(var.ssh_private_key_path)
}

data "aws_region" "current" {}

resource "aws_lightsail_instance" "example" {
  name              = var.instance_name
  blueprint_id      = "ubuntu_18_04"
  bundle_id         = "nano_1_0"
  key_pair_name     = aws_lightsail_key_pair.example.name
}

resource "aws_lightsail_key_pair" "example" {
  name       = var.key_pair_name
  public_key = file(var.ssh_public_key_path)
}

resource "aws_security_group" "example" {
  name        = var.security_group_name
  description = "Allow inbound traffic on port 22"
  vpc_id      = aws_lightsail_instance.example.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr_block]
  }
}

resource "aws_lightsail_static_ip_attachment" "example" {
  instance_name = aws_lightsail_instance.example.name
  static_ip_name = var.static_ip_name
}