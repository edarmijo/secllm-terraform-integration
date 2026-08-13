provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Create Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "example" {
  name                = "example-env"
  application         = aws_elastic_beanstalk_application.example.name
  description         = "Example environment for web app"
  tier                 = "webserver-medium"
}

resource "aws_elastic_beanstalk_application" "example" {
  name        = "example-app"
  description = "Example application for web app"
}

# Create IAM Roles and Policies
resource "aws_iam_role" "beanstalk_ec2_instance_profile" {
  name               = "BeanstalkEC2InstanceProfile"
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

resource "aws_iam_role_policy" "beanstalk_ec2_instance_profile_policy" {
  name   = "BeanstalkEC2InstanceProfilePolicy"
  role   = aws_iam_role.beanstalk_ec2_instance_profile.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.example.arn
      },
    ]
  })
}

resource "aws_iam_role" "beanstalk_rds_instance_profile" {
  name               = "BeanstalkRDSInstanceProfile"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "beanstalk_rds_instance_profile_policy" {
  name   = "BeanstalkRDSInstanceProfilePolicy"
  role   = aws_iam_role.beanstalk_rds_instance_profile.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.example.arn
      },
    ]
  })
}

# Create VPC and Subnets
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2b"
}

# Create Route Table and Routes
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.example.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.example.id
}

# Create RDS Instance
resource "aws_db_instance" "example" {
  identifier           = "example-rds"
  instance_class       = "db.t2.micro"
  engine               = "mysql"
  username             = var.db_username
  password             = var.db_password
  vpc_security_group_ids = [aws_security_group.example.id]
  db_subnet_group_name = aws_db_subnet_group.example.name
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow inbound traffic on port 3306"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }
}

resource "aws_db_subnet_group" "example" {
  name       = "example-sg"
  subnet_ids = [aws_subnet.public1.id, aws_subnet.public2.id]
}