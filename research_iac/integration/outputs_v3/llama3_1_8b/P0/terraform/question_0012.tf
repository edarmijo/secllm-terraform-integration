provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "beanstalk_blue" {
  name        = "ElasticBeanstalkBlueRole"
  description = "Elastic Beanstalk Blue Environment Role"

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

resource "aws_iam_role" "beanstalk_green" {
  name        = "ElasticBeanstalkGreenRole"
  description = "Elastic Beanstalk Green Environment Role"

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

resource "aws_iam_role_policy" "beanstalk_blue" {
  name   = "ElasticBeanstalkBluePolicy"
  role   = aws_iam_role.beanstalk_blue.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "beanstalk_green" {
  name   = "ElasticBeanstalkGreenPolicy"
  role   = aws_iam_role.beanstalk_green.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_elastic_beanstalk_environment" "blue" {
  name                = "beanstalk-blue-env"
  application         = aws_elastic_beanstalk_application.beanstalk.name
  environment_name    = "dev"
  tier               = "webserver-medium"
  platform            = "64bit Amazon Linux 2 v3.0.0 running Docker"
}

resource "aws_elastic_beanstalk_environment" "green" {
  name                = "beanstalk-green-env"
  application         = aws_elastic_beanstalk_application.beanstalk.name
  environment_name    = "dev"
  tier               = "webserver-medium"
  platform            = "64bit Amazon Linux 2 v3.0.0 running Docker"
}

resource "aws_elastic_beanstalk_application" "beanstalk" {
  name        = "beanstalk-app"
  description = "Elastic Beanstalk Application"
}

resource "aws_route53_zone" "example" {
  name            = "example.com."
}

resource "aws_route53_record" "blue" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "blue.example.com."
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.blue.cname
    zone_id                = aws_elastic_beanstalk_environment.blue.zone_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "green" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "green.example.com."
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.green.cname
    zone_id                = aws_elastic_beanstalk_environment.green.zone_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "example.com."
  type    = "A"

  weighted_routing_policy {
    weight = 10
  }

  alias {
    name                   = aws_elastic_beanstalk_environment.blue.cname
    zone_id                = aws_elastic_beanstalk_environment.blue.zone_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "example_green" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "example.com."
  type    = "A"

  weighted_routing_policy {
    weight = 90
  }

  alias {
    name                   = aws_elastic_beanstalk_environment.green.cname
    zone_id                = aws_elastic_beanstalk_environment.green.zone_name
    evaluate_target_health = false
  }
}