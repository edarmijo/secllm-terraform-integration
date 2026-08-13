provider "aws" {
  region = "us-east-1"
}

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
  name = "eb_ec2_profile"
  role = aws_iam_role.eb_ec2_profile.name
}

resource "aws_db_instance" "default" {
  engine               = "mysql"
  allocated_storage    = 10
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "root"
  password             = var.rds_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_elastic_beanstalk_environment" "default" {
  name        = "my-environment"
  application = "my-application"
  tier        = "WebServer"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }
}