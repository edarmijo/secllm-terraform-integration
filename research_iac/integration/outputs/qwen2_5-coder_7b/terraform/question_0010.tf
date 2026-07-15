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

resource "aws_s3_bucket" "sampleapril26426" {
  bucket = "sampleapril26426"
}

resource "aws_s3_object" "examplebucket_object" {
  bucket = aws_s3_bucket.sampleapril26426.bucket
  key    = "example.txt"
  source = "path/to/local/file.txt"
}

resource "aws_elastic_beanstalk_application" "myapp" {
  name        = "myapp"
  description = "My Elastic Beanstalk Application"
}

resource "aws_elastic_beanstalk_environment" "myenv" {
  application       = aws_elastic_beanstalk_application.myapp.name
  environment_name  = "myenv"
  solution_stack_name = "64bit Amazon Linux 2 v3.5.1 running Python 3.8"

  instance_profile = aws_iam_instance_profile.eb_ec2_profile.arn

  option_settings = [
    {
      namespace        = "aws:ec2:vpc"
      option_name      = "VPCId"
      value            = "vpc-0123456789abcdef0"
    },
    {
      namespace        = "aws:ec2:vpc"
      option_name      = "Subnets"
      value            = ["subnet-0123456789abcdef0", "subnet-0987654321fedcba0"]
    },
  ]
}

resource "aws_elastic_beanstalk_application_version" "version" {
  application       = aws_elastic_beanstalk_application.myapp.name
  version_label     = "version"
  source_bundle {
    s3_bucket = aws_s3_bucket.sampleapril26426.bucket
    s3_key    = aws_s3_object.examplebucket_object.key
  }
}