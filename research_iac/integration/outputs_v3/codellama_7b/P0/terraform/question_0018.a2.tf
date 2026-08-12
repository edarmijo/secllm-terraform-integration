provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "webapp_role" {
  name        = "WebAppRole"
  description = "IAM role for web application access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "webapp_policy" {
  name   = "WebAppPolicy"
  role   = aws_iam_role.webapp_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
          "dynamodb:*",
          "rds:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_vpc" "webapp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
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
}

resource "aws_subnet" "webapp_subnet2" {
  cidr_block        = "10.0.2.0/24"
  vpc_id            = aws_vpc.webapp_vpc.id
  availability_zone = "us-east-1b"
}

resource "aws_route_table" "webapp_rt" {
  vpc_id = aws_vpc.webapp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.webapp_igw.id
  }
}

resource "aws_route_table_association" "webapp_rt_assoc1" {
  subnet_id      = aws_subnet.webapp_subnet1.id
  route_table_id = aws_route_table.webapp_rt.id
}

resource "aws_route_table_association" "webapp_rt_assoc2" {
  subnet_id      = aws_subnet.webapp_subnet2.id
  route_table_id = aws_route_table.webapp_rt.id
}

resource "aws_db_instance" "webapp_rds" {
  engine               = "mysql"
  allocated_storage    = 10
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "root"
  password             = "password"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_elastic_beanstalk_application" "webapp_eb_app" {
  name        = "WebAppEB"
}

resource "aws_iam_instance_profile" "webapp_instance_profile" {
  name = "WebAppInstanceProfile"
  role = aws_iam_role.webapp_role.name
}

resource "aws_elastic_beanstalk_environment" "webapp_eb" {
  name        = "WebAppEB"
  application = aws_elastic_beanstalk_application.webapp_eb_app.name
  tier        = "Worker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.webapp_instance_profile.arn
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }
}