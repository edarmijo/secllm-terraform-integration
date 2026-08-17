provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_record" "us-east-1" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "us-east-1"
  type    = "A"
  alias {
    name                   = "myenv_us_east.elasticbeanstalk.com"
    zone_id                = "Z1176GP1Q75JJDK"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "eu-west-1" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "eu-west-1"
  type    = "A"
  alias {
    name                   = "myenv_eu_west.elasticbeanstalk.com"
    zone_id                = "Z215JYRBT5YJ1R"
    evaluate_target_health = true
  }
}

resource "aws_elastic_beanstalk_environment" "myenv_us_east" {
  name        = "myenv_us_east"
  application = "myapp_us_east"
  instance_profile = "eb_ec2_profile3"
  database_name = "main_db_us_east"
}

resource "aws_elastic_beanstalk_environment" "myenv_eu_west" {
  name        = "myenv_eu_west"
  application = "myapp_eu_west"
  instance_profile = "eb_ec2_profile3"
  database_name = "main_db_eu_west"
}

resource "aws_elastic_beanstalk_application" "myapp_us_east" {
  name        = "myapp_us_east"
  description = "My application in the us-east-1 region"
}

resource "aws_elastic_beanstalk_application" "myapp_eu_west" {
  name        = "myapp_eu_west"
  description = "My application in the eu-west-1 region"
}

resource "aws_iam_instance_profile" "eb_ec2_profile3" {
  name = "eb_ec2_profile3"
  role = aws_iam_role.eb_ec2_role3.name
}

resource "aws_iam_role" "eb_ec2_role3" {
  name = "eb_ec2_role3"
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

resource "aws_iam_role_policy" "eb_ec2_policy3" {
  name = "eb_ec2_policy3"
  role = aws_iam_role.eb_ec2_role3.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*",
        "ec2:Get*",
        "ec2:AssociateAddress"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_db_instance" "main_db_us_east" {
  identifier = "main_db_us_east"
  allocated_storage = 20
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  name = "mydb"
  username = "foo"
  password = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot = true
}

resource "aws_db_instance" "main_db_eu_west" {
  identifier = "main_db_eu_west"
  allocated_storage = 20
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  name = "mydb"
  username = "foo"
  password = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot = true
}