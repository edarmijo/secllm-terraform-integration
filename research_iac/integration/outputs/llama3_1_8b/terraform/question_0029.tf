provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "beanstalk_exec_role" {
  name        = "BeanstalkExecRole"
  description = "Execution role for Elastic Beanstalk"

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

resource "aws_iam_role_policy" "beanstalk_exec_policy" {
  name   = "BeanstalkExecPolicy"
  role   = aws_iam_role.beanstalk_exec_role.id

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

resource "aws_iam_role" "beanstalk_s3_policy" {
  name        = "BeanstalkS3Policy"
  description = "Execution role for Elastic Beanstalk S3"

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

resource "aws_iam_role_policy" "beanstalk_s3_policy" {
  name   = "BeanstalkS3Policy"
  role   = aws_iam_role.beanstalk_s3_policy.id

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
        Resource = "*"
      },
    ]
  })
}

resource "aws_elastic_beanstalk_environment" "example" {
  name                = "ExampleEnvironment"
  application         = aws_elastic_beanstalk_application.example.name
  solution_stack_name = "64bit Amazon Linux 2 v3.0.5 running Go 1.16"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "vpc-12345678"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "subnet-12345678, subnet-23456789"
  }
}

resource "aws_elastic_beanstalk_application" "example" {
  name = "ExampleApplication"
}