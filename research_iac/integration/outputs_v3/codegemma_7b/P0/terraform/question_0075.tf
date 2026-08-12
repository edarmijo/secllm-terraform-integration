provider "aws" {
  region = "us-east-1"
}

resource "aws_kendra_data_source" "kendra_data_source" {
  name = "kendra_data_source"
  type = "S3"

  s3_configuration {
    bucket = "my-bucket"
    prefix = "my-prefix"
  }

  url_exclusion_patterns = ["exclude-pattern1", "exclude-pattern2"]
  url_inclusion_patterns = ["include-pattern1", "include-pattern2"]
}