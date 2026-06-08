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
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eb_ec2_role_attach" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_s3_bucket" "sampleapril26426" {
  bucket = "sampleapril26426"
  acl    = "private"
}

resource "aws_s3_object" "examplebucket_object" {
  bucket       = aws_s3_bucket.sampleapril26426.id
  key          = "examplebucket_object"
  source       = "/dev/null"
  etag         = filemd5("/dev/null")
  content_type = "application/octet-stream"
}

resource "aws_sqs_queue" "batch_job_queue" {
  name = "batch_job_queue"
}

resource "aws_elastic_beanstalk_application" "batch_job_app" {
  name        = "batch_job_app"
  description = "Application for batch processing jobs"
}

resource "aws_elastic_beanstalk_application_version" "version" {
  application     = aws_elastic_beanstalk_application.batch_job_app.name
  name            = "version"
  description     = "Version of the application"
  source_bucket   = aws_s3_bucket.sampleapril26426.id
  source_key      = aws_s3_object.examplebucket_object.id
}

resource "aws_elastic_beanstalk_environment" "worker_env" {
  name                = "batch-worker-env"
  application         = aws_elastic_beanstalk_application.batch_job_app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.7 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SQS_QUEUE_URL"
    value     = aws_sqs_queue.batch_job_queue.id
  }
}