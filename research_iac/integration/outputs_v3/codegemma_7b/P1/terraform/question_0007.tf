provider "aws" {
  region = "us-east-1"
}

variable "eb_ec2_role_name" {
  default = "eb_ec2_role"
}

variable "eb_ec2_profile_name" {
  default = "eb_ec2_profile"
}

variable "eb_app_name" {
  default = "my_api_app"
}

resource "aws_iam_role" "eb_ec2_role" {
  name = var.eb_ec2_role_name
  assume_role_policy = file("iam_policies/eb_ec2_role_policy.json")
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = var.eb_ec2_profile_name
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_elastic_beanstalk_application" "my_api_app" {
  name = var.eb_app_name
}

resource "aws_elastic_beanstalk_environment" "my_api_app_env" {
  name = "my_api_app_env"
  application = aws_elastic_beanstalk_application.my_api_app.name
  version_label = "my_api_app_version"
  tier {
    name = "WebServer"
    type = "Standard"
    version = "6.0"
  }
  option_settings {
    namespace = "aws:autoscaling:launchconfiguration"
    option_name = "IamInstanceProfile"
    value = aws_iam_instance_profile.eb_ec2_profile.name
  }
  option_settings {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    option_name = "SystemLoggers"
    value = "[{\"log_stream_name\":\"eb-activity\",\"log_level\":\"INFO\"}]"
  }
  option_settings {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    option_name = "HealthCheckType"
    value = "ELB"
  }
  option_settings {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    option_name = "HealthThreshold"
    value = "100"
  }
  option_settings {
    namespace = "aws:autoscaling:target"
    option_name = "CPUUtilization"
    value = "80"
  }
  option_settings {
    namespace = "aws:autoscaling:target"
    option_name = "ScaleInCooldown"
    value = "60"
  }
  option_settings {
    namespace = "aws:autoscaling:target"
    option_name = "ScaleOutCooldown"
    value = "60"
  }
}