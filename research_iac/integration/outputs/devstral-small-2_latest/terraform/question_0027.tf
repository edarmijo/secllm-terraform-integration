provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "eb_ec2_role" {
  name = "eb_ec2_role"

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

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_elastic_beanstalk_application" "my_application" {
  name        = "my_application"
  description = "My Elastic Beanstalk Application"
}

resource "aws_elastic_beanstalk_environment" "webserver_env" {
  name                = "webserver-env"
  application         = aws_elastic_beanstalk_application.my_application.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.1 running Node.js 14"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.micro"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
}