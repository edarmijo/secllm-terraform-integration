provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "beanstalk_exec_role" {
  name        = "beanstalk-exec-role"
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
  name   = "beanstalk-exec-policy"
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

resource "aws_elastic_beanstalk_environment" "example" {
  name                = "example-env"
  application         = aws_elastic_beanstalk_application.example.name
  tier                = "webserver"
  environment_name   = "dev"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "vpc-12345678"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = ["subnet-12345678", "subnet-23456789"]
  }
}

resource "aws_elastic_beanstalk_application" "example" {
  name        = "example-app"
  description = "Example Elastic Beanstalk application"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "vpc-12345678"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = ["subnet-12345678", "subnet-23456789"]
  }
}

resource "aws_elastic_beanstalk_application_version" "example" {
  application_name = aws_elastic_beanstalk_application.example.name
  version_label    = "v1"

  lifecycle {
    prevent_destroy = true
  }
}