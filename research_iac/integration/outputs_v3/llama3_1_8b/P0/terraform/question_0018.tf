provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "beanstalk_service_role" {
  name        = "${var.environment}-beanstalk-service-role"
  description = "Elastic Beanstalk service role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "beanstalk_service_policy" {
  name   = "${var.environment}-beanstalk-service-policy"
  role   = aws_iam_role.beanstalk_service_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "beanstalk_ec2_instance_profile" {
  name        = "${var.environment}-beanstalk-ec2-instance-profile"
  description = "Elastic Beanstalk EC2 instance profile"

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

resource "aws_iam_role_policy" "beanstalk_ec2_instance_policy" {
  name   = "${var.environment}-beanstalk-ec2-instance-policy"
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
        Effect = "Allow"
        Resource = "${aws_s3_bucket.beanstalk_bucket.arn}/*"
      },
    ]
  })
}

resource "aws_iam_role" "beanstalk_rds_instance_profile" {
  name        = "${var.environment}-beanstalk-rds-instance-profile"
  description = "Elastic Beanstalk RDS instance profile"

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

resource "aws_iam_role_policy" "beanstalk_rds_instance_policy" {
  name   = "${var.environment}-beanstalk-rds-instance-policy"
  role   = aws_iam_role.beanstalk_rds_instance_profile.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_vpc" "beanstalk_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "beanstalk_igw" {
  vpc_id = aws_vpc.beanstalk_vpc.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

resource "aws_subnet" "beanstalk_subnet1" {
  vpc_id     = aws_vpc.beanstalk_vpc.id
  cidr_block = "10.0.1.0/24"

  availability_zone = "us-west-2a"

  tags = {
    Name = "${var.environment}-subnet1"
  }
}

resource "aws_subnet" "beanstalk_subnet2" {
  vpc_id     = aws_vpc.beanstalk_vpc.id
  cidr_block = "10.0.2.0/24"

  availability_zone = "us-west-2b"

  tags = {
    Name = "${var.environment}-subnet2"
  }
}

resource "aws_route_table" "beanstalk_rt" {
  vpc_id = aws_vpc.beanstalk_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.beanstalk_igw.id
  }

  tags = {
    Name = "${var.environment}-rt"
  }
}

resource "aws_route_table_association" "beanstalk_rta1" {
  subnet_id      = aws_subnet.beanstalk_subnet1.id
  route_table_id = aws_route_table.beanstalk_rt.id
}

resource "aws_route_table_association" "beanstalk_rta2" {
  subnet_id      = aws_subnet.beanstalk_subnet2.id
  route_table_id = aws_route_table.beanstalk_rt.id
}

resource "aws_security_group" "beanstalk_sg" {
  name        = "${var.environment}-sg"
  description = "Security group for Elastic Beanstalk environment"

  vpc_id = aws_vpc.beanstalk_vpc.id

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

resource "aws_elastic_beanstalk_environment" "beanstalk_env" {
  name                = "${var.environment}-env"
  application         = aws_elastic_beanstalk_application.beanstalk_app.name
  tier                = "webserver-medium"
  environment_name   = "${var.environment}"
  version_label      = "v1"

  setting {
    namespace = "aws:ec2:vpc"
    name       = "VPCId"
    value      = aws_vpc.beanstalk_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name       = "Subnets"
    value      = "${aws_subnet.beanstalk_subnet1.id},${aws_subnet.beanstalk_subnet2.id}"
  }
}

resource "aws_elastic_beanstalk_application" "beanstalk_app" {
  name        = "${var.environment}-app"
  description = "Elastic Beanstalk application for ${var.environment} environment"

  setting {
    namespace = "aws:ec2:vpc"
    name       = "VPCId"
    value      = aws_vpc.beanstalk_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name       = "Subnets"
    value      = "${aws_subnet.beanstalk_subnet1.id},${aws_subnet.beanstalk_subnet2.id}"
  }
}

resource "aws_rds_instance" "beanstalk_db" {
  instance_class = "db.t2.micro"

  vpc_security_group_ids = [aws_security_group.beanstalk_sg.id]

  db_instance_identifier = "${var.environment}-db"
  engine                 = "mysql"
  username               = "admin"
  password               = "password"
  db_subnet_group_name  = aws_db_subnet_group.beanstalk_db_subnet.name

  tags = {
    Name = "${var.environment}-db"
  }
}

resource "aws_db_subnet_group" "beanstalk_db_subnet" {
  name       = "${var.environment}-db-subnet-group"
  description = "Database subnet group for ${var.environment} environment"

  subnet_ids = [aws_subnet.beanstalk_subnet1.id, aws_subnet.beanstalk_subnet2.id]
}