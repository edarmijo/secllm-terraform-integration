provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "beanstalk_exec_role" {
  name        = "ElasticBeanstalkExecRole"
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
  name   = "ElasticBeanstalkExecPolicy"
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
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "Development"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:env"
    name      = "ApplicationHealthBucketName"
    value     = "example-bucket"
  }
}

resource "aws_elastic_beanstalk_application" "example" {
  name = "example-app"
}

resource "aws_elastic_beanstalk_environment_config" "example" {
  application_name = aws_elastic_beanstalk_application.example.name
  environment_name = aws_elastic_beanstalk_environment.example.name

  setting {
    namespace = "aws:elasticbeanstalk:application:env"
    name      = "ManagedUpdatesEnabled"
    value     = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:env"
    name      = "VersionLifecycleConfig"
    value     = jsonencode({
      MaxAgeRule = {
        Enabled = true
        MaxAgeInDays = 5
      }
    })
  }
}