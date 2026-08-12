provider "aws" {
  region = "us-east-1"
}

resource "aws_elastic_beanstalk_application" "app" {
  name = "my-app"
}

resource "aws_elastic_beanstalk_application_version" "version" {
  application = aws_elastic_beanstalk_application.app.name
  source_bundle {
    s3_bucket = "my-app-bucket"
    s3_key = "app.zip"
  }
  version_label = "1.0"
}

resource "aws_elastic_beanstalk_app_version_lifecycle" "lifecycle" {
  application = aws_elastic_beanstalk_application.app.name
  version_lifecycle_config {
    max_age_in_days = 30
    max_versions = 5
  }
}