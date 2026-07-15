provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "beanstalk_exec_role" {
  name        = "elastic-beanstalk-exec-role"
  description = "Role for Elastic Beanstalk to execute tasks"

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
  name   = "elastic-beanstalk-exec-policy"
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
  name        = "elastic-beanstalk-s3-policy"
  description = "Role for Elastic Beanstalk to access S3"

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
  name   = "elastic-beanstalk-s3-policy"
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
  name                = "example-env"
  application         = aws_elastic_beanstalk_application.example.name
  solution_stack_name = "64bit Amazon Linux 2 v3.1.0 running Docker"

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
  name = "example-app"
}