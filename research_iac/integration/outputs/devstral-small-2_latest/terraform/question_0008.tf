provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "eb_ec2_role" {
  name               = "eb_ec2_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_elastic_beanstalk_application" "my_application" {
  name        = "my_application"
  description = "My Elastic Beanstalk Application"
}

resource "aws_elastic_beanstalk_environment" "env1" {
  name                = "env1"
  application         = aws_elastic_beanstalk_application.my_application.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.7 running Node.js 14"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }
}

resource "aws_elastic_beanstalk_environment" "env2" {
  name                = "env2"
  application         = aws_elastic_Beanstalk_application.my_application.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.7 running Node.js 14"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }
}