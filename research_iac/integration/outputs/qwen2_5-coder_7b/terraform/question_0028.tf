provider "aws" {
  region = var.region
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
  name = "elastic-beanstalk-policy"
  role = aws_iam_role.elastic_beanstalk.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:TerminateInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeAvailabilityZones",
          "ec2:ModifyInstanceAttribute",
          "ec2:RunInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:DescribeInstanceHealth",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:SetLoadBalancerListenerSecurityGroups",
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:GetMetricStatistics",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_elastic_beanstalk_application" "example" {
  application_name = var.application_name
}