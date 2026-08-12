provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "eb_ec2_role" {
  name               = "eb_ec2_role"
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
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribePolicies",
          "autoscaling:DescribeScheduledActions",
          "ec2:DescribeInstances",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_elastic_beanstalk_environment" "my_api_env" {
  name                = "my-api-env"
  application         = aws_elastic_beanstalk_application.my_api_app.id
  tier                = "webserver"
  version_label       = "v1"
  setting {
    namespace = "aws:autoscaling:updatePolicy:coldStart"
    name      = "Enabled"
    value     = "true"
  }
  setting {
    namespace = "aws:autoscaling:updatePolicy:thresholds"
    name      = "ScaleOutCooldown"
    value     = "300"
  }
  setting {
    namespace = "aws:autoscaling:updatePolicy:thresholds"
    name      = "ScaleInCooldown"
    value     = "300"
  }
  setting {
    namespace = "aws:autoscaling:updatePolicy:thresholds"
    name      = "LowerThreshold"
    value     = "50"
  }
  setting {
    namespace = "aws:autoscaling:updatePolicy:thresholds"
    name      = "UpperThreshold"
    value     = "80"
  }
}

resource "aws_elastic_beanstalk_application" "my_api_app" {
  name = "my-api-app"
}