provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_elasticbeanstalk_application" "myenv" {
  name = "myenv"
}

resource "aws_elasticbeanstalk_environment" "myenv" {
  application = aws_elasticbeanstalk_application.myenv.name
  instance_profile_arn = aws_iam_instance_profile.eb_ec2_profile1.arn

  setting {
    name  = "AWSEBDockerrunVersion"
    value = "1"
  }

  setting {
    name  = "ContainerPort"
    value = "8080"
  }
}

resource "aws_iam_instance_profile" "eb_ec2_profile1" {
  name = "eb_ec2_profile1"
  role = aws_iam_role.eb_ec2_role1.name
}

resource "aws_iam_role" "eb_ec2_role1" {
  name = "eb_ec2_role1"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "elasticbeanstalk.amazonaws.com"
        ]
      },
      "Action": [
        "sts:AssumeRole"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "eb_ec2_role1" {
  name = "eb_ec2_role1"
  role = aws_iam_role.eb_ec2_role1.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": "*"
    }
  ]
}
EOF
}

resource "aws_rds_instance" "myapp_db" {
  identifier = "myapp_db"
  engine     = "mysql"

  instance_class   = "db.t2.small"
  allocated_storage = 10

  username = "myuser"
  password = "mypassword"
}