provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "webapp_role" {
  name        = "WebAppRole"
  description = "IAM role for web application access"

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

resource "aws_iam_role_policy" "webapp_policy" {
  name        = "WebAppPolicy"
  role        = aws_iam_role.webapp_role.name
  description = "IAM policy for web application access"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::my-webapp-bucket/*"
    },
    {
      "Action": [
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:::my-webapp-table/*"
    }
  ]
}
EOF
}

resource "aws_vpc" "webapp_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "WebAppVPC"
  }
}

resource "aws_internet_gateway" "webapp_igw" {
  vpc_id = aws_vpc.webapp_vpc.id

  tags = {
    Name = "WebAppIGW"
  }
}

resource "aws_subnet" "webapp_subnet1" {
  cidr_block        = "10.0.1.0/24"
  vpc_id            = aws_vpc.webapp_vpc.id
  availability_zone = "us-east-1a"

  tags = {
    Name = "WebAppSubnet1"
  }
}

resource "aws_subnet" "webapp_subnet2" {
  cidr_block        = "10.0.2.0/24"
  vpc_id            = aws_vpc.webapp_vpc.id
  availability_zone = "us-east-1b"

  tags = {
    Name = "WebAppSubnet2"
  }
}

resource "aws_route_table" "webapp_rt" {
  vpc_id = aws_vpc.webapp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.webapp_igw.id
  }

  tags = {
    Name = "WebAppRT"
  }
}

resource "aws_route_table_association" "webapp_rta1" {
  subnet_id      = aws_subnet.webapp_subnet1.id
  route_table_id = aws_route_table.webapp_rt.id
}

resource "aws_route_table_association" "webapp_rta2" {
  subnet_id      = aws_subnet.webapp_subnet2.id
  route_table_id = aws_route_table.webapp_rt.id
}

resource "aws_db_instance" "webapp_rds" {
  identifier             = "my-webapp-rds"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  name                   = "my_webapp_database"
  username               = "admin"
  password               = var.rds_password
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  publicly_accessible     = false
  db_subnet_group_name   = aws_db_subnet_group.webapp_rds_sg.name
  vpc_security_group_ids = [aws_security_group.webapp_rds_sg.id]
}

resource "aws_db_subnet_group" "webapp_rds_sg" {
  name       = "WebAppRdsSG"
  subnet_ids = [aws_subnet.webapp_subnet1.id, aws_subnet.webapp_subnet2.id]
}

resource "aws_security_group" "webapp_rds_sg" {
  name        = "WebAppRdsSG"
  description = "Security group for web application RDS instance"
  vpc_id      = aws_vpc.webapp_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_elastic_beanstalk_environment" "webapp_eb" {
  name        = "my-webapp-eb"
  application = aws_elastic_beanstalk_application.webapp_eb.name
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.10.5 running Node.js"
  tier        = "WebServer"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.webapp_eb_ip.name
  }
}

resource "aws_elastic_beanstalk_application" "webapp_eb" {
  name        = "my-webapp-eb"
  description = "Web application Elastic Beanstalk environment"
}

resource "aws_iam_instance_profile" "webapp_eb_ip" {
  name = "WebAppEbIp"
  role = aws_iam_role.webapp_role.name
}