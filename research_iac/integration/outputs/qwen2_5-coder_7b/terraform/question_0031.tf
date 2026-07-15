provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "elastic_beanstalk" {
  name = "elastic-beanstalk-role"

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

resource "aws_iam_role_policy" "elastic_beanstalk" {
  name   = "elastic-beanstalk-policy"
  role   = aws_iam_role.elastic_beanstalk.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeInstances",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeRegions",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DescribeInstanceHealth",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
          "iam:CreateServiceLinkedRole",
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_elastic_beanstalk_application" "example" {
  name        = "my-elastic-beanstalk-app"
  description = "My Elastic Beanstalk Application"
}

resource "aws_elastic_beanstalk_environment" "example" {
  application       = aws_elastic_beanstalk_application.example.name
  environment_name  = "my-env"
  solution_stack_name = "64bit Amazon Linux 2 v3.4.1 running Python 3.8"
  version_label     = aws_elastic_beanstalk_application_version.example.label
}

resource "aws_elastic_beanstalk_application_version" "example" {
  application       = aws_elastic_beanstalk_application.example.name
  source_bundle {
    s3_bucket = "my-bucket"
    s3_key    = "my-app.zip"
  }
}