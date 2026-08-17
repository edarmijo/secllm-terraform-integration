provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_iam_role" "eb_ec2_role" {
  name = "eb_ec2_profile3"

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
  name = "eb_ec2_profile3"

  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_route53_zone" "example_zone" {
  name = "example.com"
}

resource "aws_route53_alias" "us_east_alias" {
  name = "us-east-1"
  zone_id = aws_route53_zone.example_zone.zone_id

  alias {
    name = "myapp_us_east.example.com"
    zone_id = "Z2FDTNDATAQYW2"
    evaluate_target_health = true
  }

  target_resource = aws_elastic_beanstalk_environment.myenv_us_east.dns_name
}

resource "aws_route53_alias" "eu_west_alias" {
  name = "eu-west-1"
  zone_id = aws_route53_zone.example_zone.zone_id

  alias {
    name = "myapp_eu_west.example.com"
    zone_id = "Z2FDTNDATAQYW2"
    evaluate_target_health = true
  }

  target_resource = aws_elastic_beanstalk_environment.myenv_eu_west.dns_name
}

resource "aws_elastic_beanstalk_environment" "myenv_us_east" {
  name = "myenv_us_east"
  application = "myapp_us_east"
  version_label = "latest"
  platform_version = "64bit Amazon Linux 2"

  option_settings {
    namespace = "aws:elasticbeanstalk:environment"
    option_name  = "EnvironmentType"
    value       = "LoadBalanced"
  }

  option_settings {
    namespace = "aws:rds:dbinstance"
    option_name  = "DBName"
    value       = "main_db_us_east"
  }

  instance_profile = aws_iam_instance_profile.eb_ec2_profile.name
}

resource "aws_elastic_beanstalk_environment" "myenv_eu_west" {
  name = "myenv_eu_west"
  application = "myapp_eu_west"
  version_label = "latest"
  platform_version = "64bit Amazon Linux 2"

  option_settings {
    namespace = "aws:elasticbeanstalk:environment"
    option_name  = "EnvironmentType"
    value       = "LoadBalanced"
  }

  option_settings {
    namespace = "aws:rds:dbinstance"
    option_name  = "DBName"
    value       = "main_db_eu_west"
  }

  instance_profile = aws_iam_instance_profile.eb_ec2_profile.name
}