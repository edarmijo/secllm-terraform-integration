provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "mydomain" {
  name = "mydomain.com"
}

resource "aws_route53_record" "myenv" {
  zone_id = aws_route53_zone.mydomain.zone_id
  name    = "myenv.mydomain.com"
  type    = "A"
  alias {
    name = "myenv.elasticbeanstalk.com"
    zone_id = "Z2FDTNDATAQYW2"
  }
}

resource "aws_elastic_beanstalk_environment" "myenv" {
  name = "myenv"
  application = "myapp"
  version      = "latest"
  instance_profile_name = "eb_ec2_profile1"
}

resource "aws_rds_db_instance" "myapp_db" {
  name = "myapp_db"
  engine = "mysql"
  # ... other configuration options
}

resource "aws_elastic_beanstalk_application_version" "myapp" {
  application_name = "myapp"
  version_label    = "latest"
  source_bundle {
    # ... source code or deployment package
  }
}

resource "aws_iam_instance_profile" "eb_ec2_profile1" {
  name = "eb_ec2_profile1"

  role = aws_iam_role.myenv_role.name
}

resource "aws_iam_role" "myenv_role" {
  name = "myenv_role"

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

  policy = aws_iam_policy.myenv_policy.arn
}

resource "aws_iam_policy" "myenv_policy" {
  name = "myenv_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticbeanstalk:*",
        "rds:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}