provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "example" {
  name    = "example.com"
  comment = "Route 53 zone for example.com"
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "www"
  type    = "A"
  alias {
    name                   = "myenv.elasticbeanstalk.com"
    zone_id                = "Z1176GP1QNTPNN"
    evaluate_target_health = true
  }
}

resource "aws_iam_role" "eb_ec2_profile1" {
  name        = "eb_ec2_profile1"
  description = "IAM role for Elastic Beanstalk EC2 instances"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "eb_ec2_profile1" {
  name        = "eb_ec2_profile1"
  role        = aws_iam_role.eb_ec2_profile1.id
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "rds:*",
      "Effect": "Allow",
      "Resource": "arn:aws:rds:us-east-1:${var.aws_account_id}:db:myapp_db"
    }
  ]
}
EOF
}

resource "aws_elastic_beanstalk_environment" "myenv" {
  name        = "myenv"
  description = "Elastic Beanstalk environment for myapp"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile1.name
  }
}

resource "aws_elastic_beanstalk_environment" "myenv" {
  name        = "myenv"
  description = "Elastic Beanstalk environment for myapp"

  setting {
    namespace = "aws:rds:dbinstance"
    name      = "DBInstanceIdentifier"
    value     = aws_db_instance.myapp_db.id
  }
}