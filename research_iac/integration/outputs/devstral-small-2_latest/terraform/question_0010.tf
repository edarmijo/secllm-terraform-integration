provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "eb_ec2_role" {
  name = "eb_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_s3_bucket" "sampleapril26426" {
  bucket = "sampleapril26426"
}

resource "aws_s3_object" "examplebucket_object" {
  bucket = aws_s3_bucket.sampleapril26426.id
  key    = "examplebucket_object"
  source = "/dev/null"
}

resource "aws_elastic_beanstalk_application" "myapp" {
  name        = "myapp"
  description = "My Elastic Beanstalk application"
}

resource "aws_elastic_beanstalk_application_version" "version" {
  name        = "version"
  application = aws_elastic_beanstalk_application.myapp.name
  description = "Application Version 1"
  bucket      = aws_s3_bucket.sampleapril26426.id
  key         = aws_s3_object.examplebucket_object.id
}

resource "aws_elastic_beanstalk_environment" "env" {
  name                = "myapp-env"
  application         = aws_elastic_beanstalk_application.myapp.name
  solution_stack_name = "64bit Amazon Linux 2 v5.8.0 running Node.js 18"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
}