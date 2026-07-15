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
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_elastic_beanstalk_environment" "example" {
  name                = "example-env"
  application         = aws_elastic_beanstalk_application.example.name
  tier                = "webserver"
  environment_name    = "dev"
  solution_stack_name = "64bit Amazon Linux 2 v3.0.1 running Docker"

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "Development"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = "my-key-pair"
  }
}

resource "aws_elastic_beanstalk_application" "example" {
  name        = "example-app"
  description = "Example Elastic Beanstalk application"

  app_version_lifecycle {
    service_role = aws_iam_role.beanstalk_exec_role.arn
  }
}