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

resource "aws_iam_role_policy" "elastic_beanstalk_policy" {
  name = "elastic-beanstalk-policy"
  role = aws_iam_role.elastic_beanstalk.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateEnvironment",
          "ec2:TerminateInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeAvailabilityZones",
          "ec2:AllocateAddress",
          "ec2:AssociateAddress",
          "ec2:DisassociateAddress",
          "ec2:ReleaseAddress",
          "elb:CreateLoadBalancer",
          "elb:DeleteLoadBalancer",
          "elb:DescribeLoadBalancers",
          "elb:RegisterInstancesWithLoadBalancer",
          "elb:DeregisterInstancesFromLoadBalancer",
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:DescribeAutoScalingGroups",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:GetMetricStatistics",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_elastic_beanstalk_application" "my_app" {
  name        = "my-go-app"
  description = "My Go application on Elastic Beanstalk"
}

resource "aws_elastic_beanstalk_environment" "my_env" {
  application       = aws_elastic_beanstalk_application.my_app.name
  environment_name  = "my-go-env"
  solution_stack_name = "64bit Amazon Linux 2 v3.4.1 running Go 1.17"

  option_settings = [
    {
      namespace        = "aws:elasticbeanstalk:environment"
      option_name      = "EnvironmentType"
      value            = "SingleInstance"
    },
    {
      namespace        = "aws:ec2:vpc"
      option_name      = "VPCId"
      value            = "vpc-12345678" # Replace with your VPC ID
    },
    {
      namespace        = "aws:ec2:vpc"
      option_name      = "Subnets"
      value            = ["subnet-12345678", "subnet-87654321"] # Replace with your subnet IDs
    },
    {
      namespace        = "aws:ec2:vpc"
      option_name      = "SecurityGroups"
      value            = ["sg-12345678"] # Replace with your security group ID
    },
  ]
}