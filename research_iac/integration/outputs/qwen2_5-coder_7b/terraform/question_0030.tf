provider "aws" {
  region = var.region
}

variable "region" {
  description = "The AWS region to deploy the resources"
  type        = string
}

resource "aws_iam_role" "web_app_role" {
  name = "web-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "web_app_policy" {
  name   = "web-app-policy"
  role = aws_iam_role.web_app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:DescribeInstances",
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_security_group" "web_app_sg" {
  name        = "web-app-sg"
  description = "Security group for web application"

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_instance" "web_app_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.web_app_sg.name]

  tags = {
    Name = "WebAppInstance"
  }
}

variable "ami_id" {
  description = "The AMI ID to use for the web application instance"
  type        = string
}

variable "instance_type" {
  description = "The instance type to use for the web application instance"
  type        = string
}

variable "key_name" {
  description = "The key pair name to use for SSH access"
  type        = string
}