provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "webserver_role" {
  name               = "webserver_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "webserver_policy" {
  name   = "webserver_policy"
  role   = aws_iam_role.webserver_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::example_bucket/*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_vpc" "webserver_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "webserver_vpc"
  }
}

resource "aws_internet_gateway" "webserver_igw" {
  vpc_id = aws_vpc.webserver_vpc.id

  tags = {
    Name = "webserver_igw"
  }
}

resource "aws_subnet" "webserver_public_subnet" {
  cidr_block     = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  vpc_id          = aws_vpc.webserver_vpc.id

  tags = {
    Name = "webserver_public_subnet"
  }
}

resource "aws_route_table" "webserver_public_rt" {
  vpc_id = aws_vpc.webserver_vpc.id

  route {
    gateway_id = aws_internet_gateway.webserver_igw.id
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "webserver_public_rt"
  }
}

resource "aws_route_table_association" "webserver_public_subnet_ association" {
  subnet_id      = aws_subnet.webserver_public_subnet.id
  route_table_id = aws_route_table.webserver_public_rt.id
}

resource "aws_db_instance" "webserver_rds" {
  identifier           = "webserver_rds"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "webserver_rds"
  username             = "admin"
  password             = "password123"
  skip_final_snapshot = true
  storage_type         = "gp2"

  tags = {
    Name = "webserver_rds"
  }
}