provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_iam_role" "eb_ec2_role" {
  name               = "eb_ec2_role"
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

resource "aws_db_instance" "prod_db" {
  identifier = "prod-db"
  allocated_storage = 20
  engine = "mysql"
  instance_class = "db.t3.micro"
  name = "mydb"
  username = "foo"
  password = "bar"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot = true
}

resource "aws_db_instance" "staging_db" {
  identifier = "staging-db"
  allocated_storage = 20
  engine = "mysql"
  instance_class = "db.t3.micro"
  name = "mydb"
  username = "foo"
  password = "bar"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot = true
}

resource "aws_elastic_beanstalk_application" "example" {
  name        = "production-env"
}

resource "aws_elastic_beanstalk_application_version" "example" {
  application = aws_elastic_beanstalk_application.example.name
  version_label = "1.0"
}

resource "aws_elastic_beanstalk_environment" "production" {
  name        = "production-env"
  application = aws_elastic_beanstalk_application.example.name
  version_label = aws_elastic_beanstalk_application_version.example.name
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.10.5 running Multi-container Docker 18.09.7 (Generic)"
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }
}

resource "aws_elastic_beanstalk_environment" "staging" {
  name        = "staging-env"
  application = aws_elastic_beanstalk_application.example.name
  version_label = aws_elastic_beanstalk_application_version.example.name
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.10.5 running Multi-container Docker 18.09.7 (Generic)"
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }
}