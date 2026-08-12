provider "aws" {
  region = "us-east-1"
}

resource "aws_elastic_beanstalk_application" "example" {
  name        = "example-app"
  description = "Example Elastic Beanstalk application"
}

resource "aws_elastic_beanstalk_environment" "example" {
  name                   = "example-env"
  application            = aws_elastic_beanstalk_application.example.name
  solution_stack_name    = "64bit Amazon Linux 2018.03 v2.11.5 running Docker 18.09.9-ce"
  tier                   = "WebServer"
  version_label          = "example-version"
  wait_for_ready_timeout = "1m"
}

resource "aws_elastic_beanstalk_application_version" "example" {
  application            = aws_elastic_beanstalk_application.example.name
  description           = "Example Elastic Beanstalk application version"
  bucket                 = "example-bucket"
  key                    = "example-key"
  bundle_type            = "zip"
  wait_for_ready_timeout = "1m"
}