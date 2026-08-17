provider "aws" {
  region = ["us-east-1", "eu-west-1"]
}

resource "aws_iam_role" "eb_ec2_role" {
  name = "eb_ec2_profile3"

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

resource "aws_elastic_beanstalk_application" "myapp_us_east" {
  name = "myapp_us_east"
}

resource "aws_elastic_beanstalk_environment" "myenv_us_east" {
  name = "myenv_us_east"
  application = aws_elastic_beanstalk_application.myapp_us_east.name
  version_label = "version1"

  instance_profile_name = aws_iam_role.eb_ec2_role.name

  database_connection_string = "jdbc:mysql://${aws_rds_db_instance.main_db_us_east.endpoint}:3306/mydb"
}

resource "aws_elastic_beanstalk_application" "myapp_eu_west" {
  name = "myapp_eu_west"
}

resource "aws_elastic_beanstalk_environment" "myenv_eu_west" {
  name = "myenv_eu_west"
  application = aws_elastic_beanstalk_application.myapp_eu_west.name
  version_label = "version1"

  instance_profile_name = aws_iam_role.eb_ec2_role.name

  database_connection_string = "jdbc:mysql://${aws_rds_db_instance.main_db_eu_west.endpoint}:3306/mydb"
}

resource "aws_route53_zone" "example_zone" {
  name = "example.com"
}

resource "aws_route53_alias" "us_east_alias" {
  zone_id = aws_route53_zone.example_zone.zone_id
  name = "us-east.example.com"
  alias {
    name = aws_elastic_beanstalk_environment.myenv_us_east.cname_prefix
    zone_id = aws_elastic_beanstalk_environment.myenv_us_east.application_dns_domain
  }
}

resource "aws_route53_alias" "eu_west_alias" {
  zone_id = aws_route53_zone.example_zone.zone_id
  name = "eu-west.example.com"
  alias {
    name = aws_elastic_beanstalk_environment.myenv_eu_west.cname_prefix
    zone_id = aws_elastic_beanstalk_environment.myenv_eu_west.application_dns_domain
  }
}

resource "aws_rds_db_instance" "main_db_us_east" {
  name = "main_db_us_east"
  engine = "mysql"
  engine_version = "5.7"
  allocated_storage = 20
  instance_class = "db.t2.micro"
  username = "admin"
  password = "password"
}

resource "aws_rds_db_instance" "main_db_eu_west" {
  name = "main_db_eu_west"
  engine = "mysql"
  engine_version = "5.7"
  allocated_storage = 20
  instance_class = "db.t2.micro"
  username = "admin"
  password = "password"
}