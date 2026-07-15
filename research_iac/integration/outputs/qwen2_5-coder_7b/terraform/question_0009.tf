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

resource "aws_iam_role_policy_attachment" "eb_ec2_policy" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkWorkerTier"
}

resource "aws_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"

  roles = [aws_iam_role.eb_ec2_role.name]
}

resource "aws_s3_bucket" "sampleapril26426" {
  bucket = "sampleapril26426"
}

resource "aws_s3_object" "examplebucket_object" {
  bucket = aws_s3_bucket.sampleapril26426.bucket
  key    = "example.txt"
  source = "./example.txt"
}

resource "aws_sqs_queue" "batch_job_queue" {
  name = "batch_job_queue"
}

resource "aws_elastic_beanstalk_application" "batch_job_app" {
  application_name = "batch_job_app"
}

resource "aws_elastic_beanstalk_environment" "worker_env" {
  environment_name   = "worker-env"
  application        = aws_elastic_beanstalk_application.batch_job_app.application_name
  solution_stack_name = "64bit Amazon Linux 2 v3.5.1 running Python 3.8"

  option_settings = [
    {
      namespace        = "aws:autoscaling:launchconfiguration"
      option_name      = "IamInstanceProfile"
      value            = aws_instance_profile.eb_ec2_profile.name
    },
    {
      namespace        = "aws:elasticbeanstalk:environment"
      option_name      = "EnvironmentType"
      value            = "Worker"
    },
  ]
}

resource "aws_elastic_beanstalk_application_version" "version" {
  application       = aws_elastic_beanstalk_application.batch_job_app.application_name
  version_label     = "version"
  source_bundle {
    s3_bucket = aws_s3_bucket.sampleapril26426.bucket
    s3_key    = aws_s3_object.examplebucket_object.key
  }
}

resource "aws_elastic_beanstalk_environment" "worker_env_with_version" {
  environment_name   = "worker-env-with-version"
  application        = aws_elastic_beanstalk_application.batch_job_app.application_name
  solution_stack_name = "64bit Amazon Linux 2 v3.5.1 running Python 3.8"

  option_settings = [
    {
      namespace        = "aws:autoscaling:launchconfiguration"
      option_name      = "IamInstanceProfile"
      value            = aws_instance_profile.eb_ec2_profile.name
    },
    {
      namespace        = "aws:elasticbeanstalk:environment"
      option_name      = "EnvironmentType"
      value            = "Worker"
    },
  ]

  version_label = aws_elastic_beanstalk_application_version.version.version_label
}