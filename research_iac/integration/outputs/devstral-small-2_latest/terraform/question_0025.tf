provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

provider "aws" {
  region = "eu-west-1"
  alias  = "eu-west-1"
}

resource "aws_iam_role" "eb_role" {
  name = "eb_ec2_profile3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eb_ec2_attach" {
  role       = aws_iam_role.eb_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "eb_ec2_profile3"
  role = aws_iam_role.eb_role.name
}

resource "aws_elastic_beanstalk_application" "us_east_app" {
  provider = aws.us-east-1
  name     = "myapp_us_east"
}

resource "aws_elastic_beanstalk_application" "eu_west_app" {
  provider = aws.eu-west-1
  name     = "myapp_eu_west"
}

resource "aws_elastic_beanstalk_environment" "us_east_env" {
  provider          = aws.us-east-1
  name              = "myenv_us_east"
  application       = aws_elastic_beanstalk_application.us_east_app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.7 running Node.js 14"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }
}

resource "aws_elastic_beanstalk_environment" "eu_west_env" {
  provider          = aws.eu-west-1
  name              = "myenv_eu_west"
  application       = aws_elastic_beanstalk_application.eu_west_app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.7 running Node.js 14"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }
}

resource "aws_db_instance" "us_east_db" {
  provider         = aws.us-east-1
  identifier       = "main_db_us_east"
  engine           = "mysql"
  instance_class   = "db.t3.micro"
  allocated_storage = 20
  username         = "admin"
  password         = "password123" # In production, use a proper secret management solution
  skip_final_snapshot = true
}

resource "aws_db_instance" "eu_west_db" {
  provider         = aws.eu-west-1
  identifier       = "main_db_eu_west"
  engine           = "mysql"
  instance_class   = "db.t3.micro"
  allocated_storage = 20
  username         = "admin"
  password         = "password123" # In production, use a proper secret management solution
  skip_final_snapshot = true
}

resource "aws_route53_zone" "main" {
  name = "example.com" # Replace with your actual domain
}

resource "aws_route53_record" "us_east_alias" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "us-east-1.example.com"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.us_east_env.cname
    zone_id                = aws_elastic_beanstalk_environment.us_east_env.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "eu_west_alias" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "eu-west-1.example.com"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.eu_west_env.cname
    zone_id                = aws_elastic_beanstalk_environment.eu_west_env.hosted_zone_id
    evaluate_target_health = true
  }
}