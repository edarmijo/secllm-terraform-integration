provider "aws" {
  region = "us-west-2"
}

data "aws_secretsmanager_secret" "lightsail_api_key" {
  name = "lightsail-api-key"
}

data "aws_secretsmanager_secret_version" "lightsail_api_key" {
  secret_id = data.aws_secretsmanager_secret.lightsail_api_key.id
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lightsail_role" {
  name        = "lightsail-role"
  description = "Role for Lightsail operations"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lightsail_policy" {
  name   = "lightsail-policy"
  role   = aws_iam_role.lightsail_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lightsail:GetInstance",
          "lightsail:GetInstances",
          "lightsail:CreateInstances",
          "lightsail:CreateStaticIp",
          "lightsail:GetStaticIp",
          "lightsail:GetStaticIps",
          "lightsail:CreateLoadBalancer",
          "lightsail:GetLoadBalancer",
          "lightsail:GetLoadBalancers",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "lightsail_profile" {
  name = "lightsail-profile"
  role = aws_iam_role.lightsail_role.name
}

resource "aws_security_group" "lightsail_sg" {
  name        = "lightsail-sg"
  description = "Security group for Lightsail instances"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lightsail_instance" "example" {
  name              = "example-lightsail"
  blueprint_id      = "ubuntu_18_04_64_bits"
  bundle_id         = "nano_1_0"
  availability_zone = "us-west-2a"
  user_data         = <<EOF
  #!/bin/bash
  EOF

  depends_on = [aws_security_group.lightsail_sg]
}

resource "aws_lightsail_static_ip" "example" {
  name = "example-static-ip"
}

resource "aws_lightsail_instance_attachment" "example" {
  instance_name = aws_lightsail_instance.example.name
  static_ip_name = aws_lightsail_static_ip.example.name
}

resource "aws_lightsail_static_ip_attachment" "example" {
  instance_name = aws_lightsail_instance.example.name
  static_ip_name = aws_lightsail_static_ip.example.name
}

resource "aws_lightsail_static_ip" "example_dualstack" {
  name = "example-static-ip-dualstack"
  ip_address_type = "dualstack"
}

resource "aws_lightsail_instance_attachment" "example_dualstack" {
  instance_name = aws_lightsail_instance.example.name
  static_ip_name = aws_lightsail_static_ip.example_dualstack.name
}