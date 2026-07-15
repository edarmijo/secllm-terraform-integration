provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "eb_ec2_role" {
  name = "eb_ec2_role"

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

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"

  roles = [
    aws_iam_role.eb_ec2_role.name,
  ]
}

resource "aws_s3_bucket" "examplebucket" {
  bucket = "${lower(var.bucket_name)}-${var.environment}-${var.region}"
}

resource "aws_s3_object" "examplebucket_object" {
  bucket = aws_s3_bucket.examplebucket.id
  key    = "example.txt"
  source = "path/to/local/file.txt"
}

resource "aws_elastic_beanstalk_application" "myapp" {
  name        = var.application_name
  description = "My Elastic Beanstalk Application"
}

resource "aws_elastic_beanstalk_environment" "eb_env" {
  application       = aws_elastic_beanstalk_application.myapp.name
  environment_name  = var.environment_name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.1 running Python 3.8"
  instance_profile  = aws_iam_instance_profile.eb_ec2_profile.arn
}

resource "aws_route53_zone" "main" {
  name = "example.com"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.example.com"
  type    = "A"
  ttl     = 300

  alias {
    name                   = aws_elastic_beanstalk_environment.eb_env.endpoint
    zone_id                = aws_elastic_beanstalk_environment.eb_env.hosted_zone_id
    evaluate_target_health = true
  }
}

variable "bucket_name" {
  description = "Unique bucket name"
  type        = string
}

variable "environment_name" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "application_name" {
  description = "Application name"
  type        = string
}