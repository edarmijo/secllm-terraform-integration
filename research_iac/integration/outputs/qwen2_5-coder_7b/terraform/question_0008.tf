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
          "elasticbeanstalk:CreateEnvironment",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:ModifyInstanceAttribute",
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
  name        = "my_application"
  description = "My Elastic Beanstalk Application"
}

resource "aws_elastic_beanstalk_environment" "env1" {
  application       = aws_elastic_beanstalk_application.my_application.name
  environment_name  = "env1"
  solution_stack_name = "64bit Amazon Linux 2 v3.5.0 running Python 3.8"
  instance_profile  = aws_iam_instance_profile.eb_ec2_profile.name
}

resource "aws_elastic_beanstalk_environment" "env2" {
  application       = aws_elastic_beanstalk_application.my_application.name
  environment_name  = "env2"
  solution_stack_name = "64bit Amazon Linux 2 v3.5.0 running Python 3.8"
  instance_profile  = aws_iam_instance_profile.eb_ec2_profile.name
}