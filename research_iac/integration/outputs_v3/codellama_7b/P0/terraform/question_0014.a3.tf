provider "aws" {
  region = "us-east-1"
}

variable "account_id" {}

resource "aws_iam_role" "eb_ec2_profile" {
  name        = "eb_ec2_profile"
  description = "IAM role for Elastic Beanstalk EC2 instances"

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

resource "aws_iam_role_policy" "eb_ec2_profile_policy" {
  name   = "eb_ec2_profile_policy"
  role   = aws_iam_role.eb_ec2_profile.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:*",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:us-east-1:${var.account_id}:table/default"
      },
    ]
  })
}

resource "aws_elastic_beanstalk_application" "example" {
  name        = "example-app"
  description = "Example Elastic Beanstalk application"
}

resource "aws_elastic_beanstalk_environment" "example" {
  name                = "example-env"
  application         = aws_elastic_beanstalk_application.example.name
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.10.5 running Node.js"
  tier                = "WebServer"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }
}