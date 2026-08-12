provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "web_app_role" {
  name = "web_app_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "web_app_policy" {
  name = "web_app_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "rds:Connect",
        "elasticbeanstalk:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "web_app_policy_attachment" {
  role       = aws_iam_role.web_app_role.name
  policy_arn = aws_iam_policy.web_app_policy.arn
}

resource "aws_vpc" "web_app_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "web_app_subnet_a" {
  vpc_id        = aws_vpc.web_app_vpc.id
  cidr_block    = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "web_app_subnet_b" {
  vpc_id        = aws_vpc.web_app_vpc.id
  cidr_block    = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_route_table" "web_app_route_table" {
  vpc_id = aws_vpc.web_app_vpc.id
}

resource "aws_route_table_association" "web_app_route_table_association_a" {
  route_table_id = aws_route_table.web_app_route_table.id
  subnet_id      = aws_subnet.web_app_subnet_a.id
}

resource "aws_route_table_association" "web_app_route_table_association_b" {
  route_table_id = aws_route_table.web_app_route_table.id
  subnet_id      = aws_subnet.web_app_subnet_b.id
}

resource "aws_internet_gateway" "web_app_internet_gateway" {
  vpc_id = aws_vpc.web_app_vpc.id
}

resource "aws_route" "web_app_route" {
  route_table_id = aws_route_table.web_app_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.web_app_internet_gateway.id
}

resource "aws_rds_db_instance" "web_app_db_instance" {
  db_name = "web_app_db"
  engine = "mysql"
  allocated_storage = 20
  instance_class = "db.t2.micro"
  username = "web_app_user"
  password = var.web_app_db_password
  vpc_security_group_ids = [aws_security_group.web_app_security_group.id]
}

resource "aws_security_group" "web_app_security_group" {
  name = "web_app_security_group"

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}