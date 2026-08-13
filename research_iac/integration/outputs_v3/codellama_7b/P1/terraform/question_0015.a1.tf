provider "aws" {
  region = "us-east-1"
}

variable "rds_password" {}

resource "aws_iam_role" "eb_ec2_profile" {
  name               = "eb_ec2_profile"
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

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = aws_iam_role.eb_ec2_profile.name
}

resource "aws_db_instance" "prod_db" {
  identifier           = "prod-db"
  allocated_storage    = 10
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "foo"
  password             = var.rds_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_db_instance" "staging_db" {
  identifier           = "staging-db"
  allocated_storage    = 10
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "foo"
  password             = var.rds_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_elastic_beanstalk_application" "example" {
  name        = "example-app"
}

resource "aws_elastic_beanstalk_environment" "production" {
  name        = "production-env"
  application = aws_elastic_beanstalk_application.example.name
  tier        = "WebServer"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.arn
  }
}

resource "aws_elastic_beanstalk_environment" "staging" {
  name        = "staging-env"
  application = aws_elastic_beanstalk_application.example.name
  tier        = "WebServer"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.arn
  }
}