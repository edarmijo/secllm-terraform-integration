provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "eb_ec2_role" {
  name = "eb_ec2_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"

  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_db_instance" "default" {
  identifier = "default"
  engine = "postgres"
  # ... other database configuration
}

resource "aws_elastic_beanstalk_environment" "default" {
  name = "default"
  application = "my_app"
  version_label = "latest"

  database_connection_string = "jdbc:postgresql://${aws_db_instance.default.endpoint}:5432/default"
  db_instance_profile_name = aws_iam_instance_profile.eb_ec2_profile.name
}