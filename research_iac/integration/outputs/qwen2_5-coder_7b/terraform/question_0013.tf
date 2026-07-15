provider "aws" {
  alias  = "us_west"
  region = "us-west-2"
}

provider "aws" {
  alias  = "eu_central"
  region = "eu-central-1"
}

resource "aws_iam_role" "eb_us_west" {
  name = "eb-us-west"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role" "eb_eu_central" {
  name = "eb-eu-central"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_elastic_beanstalk_environment" "us_west" {
  provider     = aws.us_west
  name         = "us_west"
  application  = var.application_name
  solution_stack_name = "64bit Amazon Linux 2 v3.5.1 running Python 3.8"
  environment_variables = {
    ENVIRONMENT_TYPE = "production"
  }
}

resource "aws_elastic_beanstalk_environment" "eu_central" {
  provider     = aws.eu_central
  name         = "eu_central"
  application  = var.application_name
  solution_stack_name = "64bit Amazon Linux 2 v3.5.1 running Python 3.8"
  environment_variables = {
    ENVIRONMENT_TYPE = "production"
  }
}

resource "aws_route53_zone" "global" {
  name = "example.com"
}

resource "aws_route53_record" "us_west" {
  zone_id = aws_route53_zone.global.zone_id
  name    = "us-west.example.com"
  type    = "A"
  ttl     = 300

  alias {
    name                   = aws_elastic_beanstalk_environment.us_west.endpoint
    zone_id                = aws_elastic_beanstalk_environment.us_west.vpc_config.vpc_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "eu_central" {
  zone_id = aws_route53_zone.global.zone_id
  name    = "eu-central.example.com"
  type    = "A"
  ttl     = 300

  alias {
    name                   = aws_elastic_beanstalk_environment.eu_central.endpoint
    zone_id                = aws_elastic_beanstalk_environment.eu_central.vpc_config.vpc_id
    evaluate_target_health = true
  }
}

variable "application_name" {
  description = "The name of the Elastic Beanstalk application"
  type        = string
}