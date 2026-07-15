provider "aws" {
  region = "us-west-2"
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
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:DescribeInstances",
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"

  roles = [aws_iam_role.eb_ec2_role.name]
}

resource "aws_elastic_beanstalk_application" "my_application" {
  application_name = "my_application"
}

resource "aws_elastic_beanstalk_environment" "web_server_env" {
  environment_name = "web-server-env"
  application      = aws_elastic_beanstalk_application.my_application.application_name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.1 running Python 3.8"

  option_settings = [
    {
      namespace        = "aws:ec2:vpc"
      option_name      = "VPCId"
      value            = "vpc-0123456789abcdef0" # Replace with your VPC ID
    },
    {
      namespace        = "aws:ec2:vpc"
      option_name      = "Subnets"
      value            = ["subnet-0123456789abcdef0", "subnet-0987654321fedcba0"] # Replace with your subnet IDs
    },
    {
      namespace        = "aws:ec2:vpc"
      option_name      = "ELBSubnets"
      value            = ["subnet-0123456789abcdef0", "subnet-0987654321fedcba0"] # Replace with your subnet IDs
    },
    {
      namespace        = "aws:ec2:vpc"
      option_name      = "EC2KeyName"
      value            = "my-key-pair" # Replace with your key pair name
    },
    {
      namespace        = "aws:instanceprofile"
      option_name      = "InstanceProfile"
      value            = aws_iam_instance_profile.eb_ec2_profile.arn
    }
  ]
}