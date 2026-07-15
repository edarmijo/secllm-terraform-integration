provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "beanstalk_service_role" {
  name = "beanstalk-service-role"

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

resource "aws_iam_role_policy" "beanstalk_service_policy" {
  name   = "beanstalk-service-policy"
  role   = aws_iam_role.beanstalk_service_role.id

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
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:SetDesiredCapacity",
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

  option_settings = [
    {
      namespace        = "aws:elasticbeanstalk:application"
      option_name      = "ApplicationName"
      value            = aws_elastic_beanstalk_application.example.name
    },
    {
      namespace        = "aws:elb:policies"
      option_name      = "ConnectionDrainingTimeout"
      value            = "300"
    },
  ]

  version_label = aws_elastic_beanstalk_application_version.example.label
}

resource "aws_elastic_beanstalk_application_version" "example" {
  application       = aws_elastic_beanstalk_application.example.name
  source_bundle     = {
    s3_bucket = "my-bucket"
    s3_key    = "my-app.zip"
  }
  version_label = "v1.0"

  option_settings = [
    {
      namespace        = "aws:elasticbeanstalk:environment"
      option_name      = "EnvironmentType"
      value            = "SingleInstance"
    },
  ]

  lifecycle_policy {
    max_count         = 1
    delete_source_from_s3 = true
  }
}