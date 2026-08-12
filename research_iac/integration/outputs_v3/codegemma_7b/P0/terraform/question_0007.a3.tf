provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "eb_ec2_role" {
  name = "eb_ec2_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_elastic_beanstalk_application" "my_api_app" {
  name = "my_api_app"
}

resource "aws_elastic_beanstalk_environment" "my_api_env" {
  name = "my_api_env"
  application = aws_elastic_beanstalk_application.my_api_app.name
  version_label = "my_api_version"

  option_settings {
    namespace = "aws:autoscaling:launchconfiguration"
    option_name  = "IamInstanceProfile"
    value       = aws_iam_instance_profile.eb_ec2_profile.name
  }

  option_settings {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    option_name  = "SystemLoggers"
    value       = "[{\"streamName\":\"eb-activity\",\"level\":\"INFO\"}]"
  }

  option_settings {
    namespace = "aws:elasticbeanstalk:healthreporting:guest"
    option_name  = "Enabled"
    value       = "true"
  }

  option_settings {
    namespace = "aws:autoscaling:target"
    option_name  = "CPUUtilization"
    value       = "80"
  }

  option_settings {
    namespace = "aws:autoscaling:trigger"
    option_name  = "LowerThreshold"
    value       = "70"
  }

  option_settings {
    namespace = "aws:autoscaling:trigger"
    option_name  = "UpperThreshold"
    value       = "90"
  }
}