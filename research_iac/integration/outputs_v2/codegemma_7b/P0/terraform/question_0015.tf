provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "eb_ec2_role" {
  name = "eb_ec2_profile"

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

resource "aws_rds_db_instance" "prod_db" {
  name = "prod_db"
  engine = "mysql"
  # ... other configuration options
}

resource "aws_rds_db_instance" "staging_db" {
  name = "staging_db"
  engine = "mysql"
  # ... other configuration options
}

resource "aws_elasticbeanstalk_environment" "production" {
  name = "production"
  application = "my_app"
  version = "my_app-version"
  db_instances = [aws_rds_db_instance.prod_db.db_instance_identifier]
  # ... other configuration options
}

resource "aws_elasticbeanstalk_environment" "staging" {
  name = "staging"
  application = "my_app"
  version = "my_app-version"
  db_instances = [aws_rds_db_instance.staging_db.db_instance_identifier]
  # ... other configuration options
}