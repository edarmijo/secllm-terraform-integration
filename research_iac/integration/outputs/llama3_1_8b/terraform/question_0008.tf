provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "eb_ec2_role" {
  name        = "eb_ec2_role"
  description = "Elastic Beanstalk EC2 Role"

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
        Resource = aws_s3_bucket.example.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"

  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_elastic_beanstalk_environment" "example1" {
  name               = "my-environment-1"
  application_name   = "my_application"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.10.4 running Node.js"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.example.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.example1.id
  }
}

resource "aws_elastic_beanstalk_environment" "example2" {
  name               = "my-environment-2"
  application_name   = "my_application"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.10.4 running Node.js"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.example.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.example2.id
  }
}