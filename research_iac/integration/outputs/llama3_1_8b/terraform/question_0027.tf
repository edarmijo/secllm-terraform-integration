provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "eb_ec2_role" {
  name        = "eb_ec2_role"
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
      }
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
    ]
  })
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_elastic_beanstalk_environment" "my_env" {
  name                = "my-env"
  application         = aws_elastic_beanstalk_application.my_app.name
  tier                = "webserver"
  environment_name   = "my-env"

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

resource "aws_elastic_beanstalk_application" "my_app" {
  name = "my-application"
}