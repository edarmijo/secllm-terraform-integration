provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "eb_ec2_role" {
  name        = "eb_ec2_profile"
  description = "Elastic Beanstalk EC2 role"

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

resource "aws_iam_role_policy" "eb_ec2_policy" {
  name   = "eb_ec2_policy"
  role   = aws_iam_role.eb_ec2_role.id

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
      },
    ]
  })
}

resource "aws_iam_role" "prod_db_instance_role" {
  name        = "prod_db_instance_role"
  description = "RDS instance role for production database"

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

resource "aws_iam_role_policy" "prod_db_instance_policy" {
  name   = "prod_db_instance_policy"
  role   = aws_iam_role.prod_db_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
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
  tier                 = "webserver-medium"
  platform            = "64bit Amazon Linux 2/3.1.12 running Multi-container Docker 20.10.8"
}

resource "aws_elastic_beanstalk_environment" "staging_env" {
  name                = "staging-env"
  application         = "my-app"
  description         = "Staging environment"
  tier                 = "webserver-medium"
  platform            = "64bit Amazon Linux 2/3.1.12 running Multi-container Docker 20.10.8"
}

resource "aws_elastic_beanstalk_environment" "prod_env_config" {
  name                = aws_elastic_beanstalk_environment.prod_env.name
  application         = aws_elastic_beanstalk_environment.prod_env.application
  description         = aws_elastic_beanstalk_environment.prod_env.description
  tier                 = aws_elastic_beanstalk_environment.prod_env.tier
  platform            = aws_elastic_beanstalk_environment.prod_env.platform

  setting {
    namespace = "aws:ec2:vpc"
    name       = "VPCId"
    value      = "vpc-12345678"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name       = "Subnets"
    value      = "subnet-12345678, subnet-23456789"
  }
}

resource "aws_elastic_beanstalk_environment" "staging_env_config" {
  name                = aws_elastic_beanstalk_environment.staging_env.name
  application         = aws_elastic_beanstalk_environment.staging_env.application
  description         = aws_elastic_beanstalk_environment.staging_env.description
  tier                 = aws_elastic_beanstalk_environment.staging_env.tier
  platform            = aws_elastic_beanstalk_environment.staging_env.platform

  setting {
    namespace = "aws:ec2:vpc"
    name       = "VPCId"
    value      = "vpc-12345678"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name       = "Subnets"
    value      = "subnet-12345678, subnet-23456789"
  }
}