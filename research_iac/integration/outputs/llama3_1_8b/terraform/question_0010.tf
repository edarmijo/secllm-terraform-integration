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

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_s3_bucket" "sampleapril26426" {
  bucket = "sampleapril26426"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_s3_object" "examplebucket_object" {
  bucket = aws_s3_bucket.sampleapril26426.id
  key    = "examplebucket_object"
  source = "/path/to/local/file"
}

resource "aws_elastic_beanstalk_environment" "myapp" {
  name        = "myapp"
  application = aws_elastic_beanstalk_application.myapp.name

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "vpc-12345678"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = ["subnet-12345678", "subnet-23456789"]
  }
}

resource "aws_elastic_beanstalk_application" "myapp" {
  name = "myapp"
}

resource "aws_elastic_beanstalk_application_version" "version" {
  application_name = aws_elastic_beanstalk_application.myapp.name
  version_label    = "version"
}