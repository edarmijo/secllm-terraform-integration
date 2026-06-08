provider "aws" {
  region = "us-east-1"
}

resource "aws_elastic_beanstalk_application" "app" {
  name        = "my-app"
  description = "My Elastic Beanstalk application"
}

resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.app.name
  description = "Version 1 of the application"
  bucket      = aws_s3_bucket.bucket.id
  key         = aws_s3_object.object.id
}

resource "aws_s3_bucket" "bucket" {
  bucket = "my-app-bucket"
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.bucket.id
  key    = "app.zip"
  source = "./app.zip"
}

resource "aws_elastic_beanstalk_application_version_lifecycle" "lifecycle" {
  application          = aws_elastic_beanstalk_application.app.name
  max_count            = 50
  delete_source_from_s3 = true

  rule {
    action       = "expire"
    enable       = true
    expiration_days = 5
  }
}

resource "aws_iam_role" "eb_role" {
  name = "elastic-beanstalk-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eb_policy" {
  role       = aws_iam_role.eb_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}