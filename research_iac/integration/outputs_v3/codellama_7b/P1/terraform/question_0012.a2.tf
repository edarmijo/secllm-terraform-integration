resource "aws_elastic_beanstalk_application_version" "example" {
  name         = "example-app-version"
  application  = aws_elastic_beanstalk_application.example.name
  description  = "Example Elastic Beanstalk application version"
  source_bundle {
    s3_bucket = "my-s3-bucket"
    s3_key    = "path/to/source/bundle.zip"
  }
}