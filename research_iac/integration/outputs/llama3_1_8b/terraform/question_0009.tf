provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "eb_ec2_role" {
  name        = "eb_ec2_role"
  description = "Elastic Beanstalk EC2 role"

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
  key    = "examplebucket_object.txt"
  content = "Hello, World!"
}

resource "aws_sqs_queue" "batch_job_queue" {
  name                        = "batch_job_queue"
  delay_seconds               = 60
  message_retention_period    = 345600
  receive_wait_time_seconds   = 20
  visibility_timeout           = 30
}

resource "aws_elastic_beanstalk_environment" "batch_job_env" {
  name                = "batch-job-env"
  application        = aws_elastic_beanstalk_application.batch_job_app.name
  version_label       = var.version
  environment_name   = "dev"

  setting {
    namespace = "aws:ec2:instance"
    name      = "InstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "Worker"
  }
}

resource "aws_elastic_beanstalk_application" "batch_job_app" {
  name        = "batch-job-app"
  description = "Batch job application"
}