provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "main" {
  name = "example.com"
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

resource "aws_s3_bucket" "examplebucket" {
  bucket = "examplebucket-${random_id.bucket_suffix.hex}"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_object" "examplebucket_object" {
  bucket = aws_s3_bucket.examplebucket.id
  key    = "example.txt"
  source = "/dev/null"
}

resource "aws_elastic_beanstalk_application" "myapp" {
  name        = "myapp"
  description = "My application"
}

resource "aws_elastic_beanstalk_application_version" "version" {
  name        = "version"
  application = aws_elastic_beanstalk_application.myapp.name
  source_bucket = aws_s3_bucket.examplebucket.id
  source_key    = aws_s3_object.examplebucket_object.id
}

resource "aws_elastic_beanstalk_environment" "eb_env" {
  name                = "eb-env"
  application         = aws_elastic_beanstalk_application.myapp.name
  solution_stack_name = "64bit Amazon Linux 2 v5.8.0 running Node.js 18"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.eb_env.cname
    zone_id                = aws_elastic_beanstalk_environment.eb_env.hosted_zone_id
    evaluate_target_health = true
  }
}