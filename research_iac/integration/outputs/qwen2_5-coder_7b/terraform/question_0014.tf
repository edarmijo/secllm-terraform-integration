provider "aws" {
  region = "us-west-2"
}

resource "aws_db_instance" "default" {
  identifier             = "default"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t2.micro"
  username               = "admin"
  password               = "password123!"
  allocated_storage      = 20
  vpc_security_group_ids = [aws_security_group.default.id]
}

resource "aws_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"

  role {
    name = aws_iam_role.eb_ec2_role.name
  }
}

resource "aws_iam_role" "eb_ec2_role" {
  name = "eb_ec2_role"

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

resource "aws_security_group" "default" {
  name        = "default"
  description = "Default security group"

  ingress {
    from_port   = 3306
    to_port     = 3306
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