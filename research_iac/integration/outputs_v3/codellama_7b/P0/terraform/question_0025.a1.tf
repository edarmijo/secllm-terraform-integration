provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "example.com"
  type    = "A"

  alias {
    name                   = "us-east-1.example.com"
    zone_id                = "us-east-1"
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
  description = "My application in us-east-1"
}

resource "aws_elastic_beanstalk_application" "myapp_eu_west" {
  name        = "myapp_eu_west"
  description = "My application in eu-west-1"
}

resource "aws_iam_role" "eb_ec2_profile3" {
  name = "eb_ec2_profile3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "eb_ec2_profile3" {
  name = "eb_ec2_profile3"
  role = aws_iam_role.eb_ec2_profile3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_db_instance" "main_db_us_east" {
  identifier = "main-db-us-east"
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  allocated_storage = 20
  username = "admin"
  password = "password"
  skip_final_snapshot = true
}

resource "aws_db_instance" "main_db_eu_west" {
  identifier = "main-db-eu-west"
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  allocated_storage = 20
  username = "admin"
  password = "password"
  skip_final_snapshot = true
}