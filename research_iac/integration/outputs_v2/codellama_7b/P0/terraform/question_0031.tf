provider "aws" {
  region = "us-east-1"
}

resource "aws_elastic_beanstalk_application" "example" {
  name        = "my-application"
  description = "My Elastic Beanstalk application"
}

resource "aws_elastic_beanstalk_environment" "example" {
  name                   = "my-environment"
  application            = aws_elastic_beanstalk_application.example.name
  solution_stack_name    = "64bit Amazon Linux 2018.03 v2.10.5 running Docker 18.09.7"
  tier                   = "WebServer"
  version_label          = "my-version"
  wait_for_ready_timeout = "1m"
}

resource "aws_elastic_beanstalk_application_version" "example" {
  application            = aws_elastic_beanstalk_application.example.name
  description           = "My Elastic Beanstalk application version"
  bucket                 = "my-bucket"
  key                    = "my-key"
  bundle_type            = "zip"
  timeout                = "1m"
  wait_for_deployment    = true
}

resource "aws_elastic_beanstalk_environment_application_version" "example" {
  environment_id   = aws_elastic_beanstalk_environment.example.id
  application_name = aws_elastic_beanstalk_application.example.name
  version_label    = aws_elastic_beanstalk_application_version.example.version_label
}