provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name = "example.com"
}

resource "aws_route53_record" "beanstalk_alias" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "example.com"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.myenv.cname
    zone_id                = aws_elastic_beanstalk_environment.myenv.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_iam_instance_profile" "eb_ec2_profile1" {
  name = "eb_ec2_profile1"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_iam_role" "eb_ec2_role" {
  name = "eb_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_elastic_beanstalk_environment" "myenv" {
  name                = "myenv"
  application         = "myapp"
  solution_stack_name = "64bit Amazon Linux 2 v3.4.7 running Node.js 14"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile1.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
}

resource "aws_db_instance" "myapp_db" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  name                 = "mydatabase"
  username             = "admin"
  password             = "password123"
  skip_final_snapshot  = true
}

resource "aws_elastic_beanstalk_application" "myapp" {
  name        = "myapp"
  description = "My Elastic Beanstalk application"
}