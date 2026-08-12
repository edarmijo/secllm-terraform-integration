provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "app_version_lifecycle_role" {
  name = "app_version_lifecycle_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "app_version_lifecycle_policy" {
  name = "app_version_lifecycle_policy"
  role = aws_iam_role.app_version_lifecycle_role.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticbeanstalk:*",
        "s3:*",
        "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_elastic_beanstalk_application" "app" {
  name = "my_app"
}

resource "aws_elastic_beanstalk_application_version" "version" {
  application = aws_elastic_beanstalk_application.app.name
  version_label = "my_app_version"
  source_bundle {
    s3_bucket = "my-app-bucket"
    s3_key = "my-app.zip"
  }
}

resource "aws_elastic_beanstalk_app_version_lifecycle" "lifecycle" {
  application = aws_elastic_beanstalk_application.app.name

  version_lifecycle_config {
    max_age_in_days = 30
    max_versions = 5
  }
}