provider "aws" {
  region = "us-west-2"
}

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
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "elasticbeanstalk:CreateConfigurationOption",
          "elasticbeanstalk:UpdateEnvironment",
          "elasticbeanstalk:RequestEnvironmentAction",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_elastic_beanstalk_environment" "my_api_env" {
  name                = "my-api-env"
  application         = aws_elastic_beanstalk_application.my_api_app.name
  tier                = "webserver"
  environment_name    = "my-api-env"

  setting {
    namespace = "aws:autoscaling:updatepolicy-identity"
    name      = "Enabled"
    value     = "false"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy-identity"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy-identity"
    name      = "MaxSize"
    value     = "2"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy-identity"
    name      = "ScalingAdjustment"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy-identity"
    name      = "Cooldown"
    value     = "300"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MetricName"
    value     = "CPUUtilization"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Statistic"
    value     = "Average"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Period"
    value     = "300"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "EvaluationPeriods"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MaxSize"
    value     = "2"
  }
}

resource "aws_elastic_beanstalk_application" "my_api_app" {
  name        = "my-api-app"
  description = "My API Application"
}