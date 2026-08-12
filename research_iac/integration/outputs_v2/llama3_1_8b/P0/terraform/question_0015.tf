provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "eb_ec2_profile" {
  name        = "eb_ec2_profile"
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
      }
    ]
  })
}

resource "aws_iam_role_policy" "eb_ec2_profile_policy" {
  name   = "eb_ec2_profile_policy"
  role   = aws_iam_role.eb_ec2_profile.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBParameters",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "prod_db_instance_profile" {
  name        = "prod_db_instance_profile"
  description = "Production RDS instance profile"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "prod_db_instance_profile_policy" {
  name   = "prod_db_instance_profile_policy"
  role   = aws_iam_role.prod_db_instance_profile.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBParameters",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_db_instance" "prod_db" {
  identifier           = "prod-db"
  instance_class       = "db.t2.micro"
  engine               = "mysql"
  username             = "admin"
  password             = "password"
  vpc_security_group_ids = [aws_security_group.prod_sg.id]
  db_subnet_group_name = aws_db_subnet_group.prod_subnet_group.name
}

resource "aws_db_instance" "staging_db" {
  identifier           = "staging-db"
  instance_class       = "db.t2.micro"
  engine               = "mysql"
  username             = "admin"
  password             = "password"
  vpc_security_group_ids = [aws_security_group.staging_sg.id]
  db_subnet_group_name = aws_db_subnet_group.staging_subnet_group.name
}

resource "aws_elastic_beanstalk_environment" "prod_env" {
  name                = "prod-env"
  application         = "my-app"
  description         = "Production environment"
  tier                = "webserver-medium"
  platform            = "64bit Amazon Linux 2/3.1.12 running Multi-container Docker 20-06-08 (HVM)"
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.prod_vpc.id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = jsonencode([aws_subnet.prod_subnet1.id, aws_subnet.prod_subnet2.id])
  }
}

resource "aws_elastic_beanstalk_environment" "staging_env" {
  name                = "staging-env"
  application         = "my-app"
  description         = "Staging environment"
  tier                = "webserver-medium"
  platform            = "64bit Amazon Linux 2/3.1.12 running Multi-container Docker 20-06-08 (HVM)"
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.staging_vpc.id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = jsonencode([aws_subnet.staging_subnet1.id, aws_subnet.staging_subnet2.id])
  }
}

resource "aws_security_group" "prod_sg" {
  vpc_id = aws_vpc.prod_vpc.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "staging_sg" {
  vpc_id = aws_vpc.staging_vpc.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "prod_subnet_group" {
  name       = "prod-subnet-group"
  subnet_ids = [aws_subnet.prod_subnet1.id, aws_subnet.prod_subnet2.id]
}

resource "aws_db_subnet_group" "staging_subnet_group" {
  name       = "staging-subnet-group"
  subnet_ids = [aws_subnet.staging_subnet1.id, aws_subnet.staging_subnet2.id]
}