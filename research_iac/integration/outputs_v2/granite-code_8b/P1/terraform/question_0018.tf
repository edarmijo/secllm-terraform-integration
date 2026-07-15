provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "beanstalk_role" {
  name               = "beanstalk-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "beanstalk_policy" {
  name = "beanstalk-policy"
  role = aws_iam_role.beanstalk_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket/*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Main VPC"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Main Internet Gateway"
  }
}

resource "aws_subnet" "public" {
  cidr_block = "10.0.1.0/24"
  availability_zone = var.availability_zone
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private" {
  cidr_block = "10.0.2.0/24"
  availability_zone = var.availability_zone
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    gateway_id = aws_internet_gateway.main.id
    destination_cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_rds_instance" "main" {
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t2.micro"
  name              = "my-rds-instance"
  username          = var.username
  password          = var.password
  skip_final_snapshot = true

  tags = {
    Name = "Main RDS Instance"
  }
}