provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "beanstalk_blue" {
  name        = "ElasticBeanstalkBlueRole"
  description = "IAM role for Elastic Beanstalk Blue environment"

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
  description = "IAM role for Elastic Beanstalk Green environment"

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
        Resource = aws_s3_bucket.example.arn
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
        Resource = aws_s3_bucket.example.arn
      },
    ]
  })
}

resource "aws_elastic_beanstalk_environment" "blue" {
  name                = "blue-env"
  application         = aws_elastic_beanstalk_application.example.name
  solution_stack_name = "64bit Amazon Linux 2 v4.0.7 running Docker"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.example.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.example.id
  }
}

resource "aws_elastic_beanstalk_environment" "green" {
  name                = "green-env"
  application         = aws_elastic_beanstalk_application.example.name
  solution_stack_name = "64bit Amazon Linux 2 v4.0.7 running Docker"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.example.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.example.id
  }
}

resource "aws_elastic_beanstalk_application" "example" {
  name        = "example-app"
  environment_name = aws_elastic_beanstalk_environment.blue.name
}

resource "aws_route53_zone" "example" {
  name            = "example.com"
}

resource "aws_route53_record_set" "blue" {
  zone_id = aws_route53_zone.example.zone_id
  name    = aws_elastic_beanstalk_environment.blue.cname
  type    = "CNAME"

  alias {
    name                   = aws_elastic_beanstalk_environment.blue.cname
    zone_id                = aws_elastic_beanstalk_environment.blue.zone_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record_set" "green" {
  zone_id = aws_route53_zone.example.zone_id
  name    = aws_elastic_beanstalk_environment.green.cname
  type    = "CNAME"

  alias {
    name                   = aws_elastic_beanstalk_environment.green.cname
    zone_id                = aws_elastic_beanstalk_environment.green.zone_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "example.com"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.blue.cname
    zone_id                = aws_elastic_beanstalk_environment.blue.zone_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "example_green" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "example.com"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.green.cname
    zone_id                = aws_elastic_beanstalk_environment.green.zone_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "example_blue_green" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "example.com"
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

resource "aws_route53_record" "example_green_blue" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "example.com"
  type    = "A"

  weighted_routing_policy {
    weight = 10
  }

  alias {
    name                   = aws_elastic_beanstalk_environment.green.cname
    zone_id                = aws_elastic_beanstalk_environment.green.zone_name
    evaluate_target_health = false
  }
}