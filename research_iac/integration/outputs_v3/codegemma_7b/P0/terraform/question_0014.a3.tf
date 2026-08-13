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
  instance_class = "t2.micro"
  # ... other database configuration
}

resource "aws_elastic_beanstalk_environment" "default" {
  name = "default"
  application = "my_app"
  version_label = "latest"

  connection_settings {
    database_name = "default"
    engine_name = "postgres"
    password = "your_password" # Replace with actual password
    port = 5432
    server_name = aws_db_instance.default.endpoint
    username = "your_username" # Replace with actual username
  }

  instance_profile_name = aws_iam_instance_profile.eb_ec2_profile.name
}