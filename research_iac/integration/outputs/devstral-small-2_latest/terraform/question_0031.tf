provider "aws" {
  region = "us-east-1"
}

resource "aws_elastic_beanstalk_application" "app" {
  name        = "my-eb-app"
  description = "My Elastic Beanstalk Application"
}

resource "aws_elastic_beanstalk_application_version" "app_version" {
  application     = aws_elastic_beanstalk_application.app.name
  name            = "v1.0"
  description     = "Version 1.0 of the application"
  bucket          = aws_s3_bucket.app_bucket.id
  key             = aws_s3_object.app_key.id
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = "my-eb-app-bucket-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_object" "app_key" {
  bucket = aws_s3_bucket.app_bucket.id
  key    = "my-app.zip"
  source = "./my-app.zip"
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "aws_elastic_beanstalk_application_version_lifecycle" "app_lifecycle" {
  application     = aws_elastic_beanstalk_application.app.name
  max_count       = 10
  delete_source_from_s3 = true
}