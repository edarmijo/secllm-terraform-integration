provider "aws" {
  region = var.aws_region
}

data "aws_ami" "latest_amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.latest_amazon_linux_2.id
  instance_type = "c5.xlarge"

  vpc_security_group_ids = [aws_security_group.example.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.example.name
  }

  key_name               = var.key_pair
  monitoring             = true

  root_block_device {
    volume_type           = "gp2"
    iops                  = 3000
    delete_on_termination = true
  }
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow inbound traffic on port 22"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "example" {
  name = "example-instance-profile"

  role = aws_iam_role.example.name
}

resource "aws_iam_role" "example" {
  name        = "example-role"
  description = "Allow instance to use AWS services"

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

resource "aws_iam_role_policy" "example" {
  name   = "example-role-policy"
  role   = aws_iam_role.example.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}