provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "beanstalk_blue" {
  name        = "${var.environment}-blue"
  description = "Elastic Beanstalk Blue Environment IAM Role"

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
  name        = "${var.environment}-green"
  description = "Elastic Beanstalk Green Environment IAM Role"

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
  name   = "${var.environment}-blue-policy"
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
        Resource = "${aws_s3_bucket.beanstalk_blue.arn}/*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.beanstalk_blue.arn}:*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "beanstalk_green" {
  name   = "${var.environment}-green-policy"
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
        Resource = "${aws_s3_bucket.beanstalk_green.arn}/*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.beanstalk_green.arn}:*"
      },
    ]
  })
}

resource "aws_s3_bucket" "beanstalk_blue" {
  bucket = "${var.environment}-blue-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "beanstalk_green" {
  bucket = "${var.environment}-green-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_cloudwatch_log_group" "beanstalk_blue" {
  name              = "${var.environment}-blue-log-group"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "beanstalk_green" {
  name              = "${var.environment}-green-log-group"
  retention_in_days = 30
}

resource "aws_elastic_beanstalk_environment" "beanstalk_blue" {
  name                = "${var.environment}-blue"
  application         = aws_elastic_beanstalk_application.beanstalk.name
  tier                = "webserver"
  environment_name    = "dev-blue"

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "Development"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentName"
    value     = "${var.environment}-blue"
  }
}

resource "aws_elastic_beanstalk_environment" "beanstalk_green" {
  name                = "${var.environment}-green"
  application         = aws_elastic_beanstalk_application.beanstalk.name
  tier                = "webserver"
  environment_name    = "dev-green"

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "Development"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentName"
    value     = "${var.environment}-green"
  }
}

resource "aws_elastic_beanstalk_application" "beanstalk" {
  name        = "${var.environment}"
  description = "Elastic Beanstalk Application for ${var.environment}"
}

resource "aws_route53_zone" "example" {
  name            = var.domain
  comment         = "Managed by Terraform"
}

resource "aws_route53_record" "blue" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "${var.environment}-blue.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.beanstalk_blue.cname
    zone_id                = aws_elastic_beanstalk_environment.beanstalk_blue.zone_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "green" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "${var.environment}-green.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.beanstalk_green.cname
    zone_id                = aws_elastic_beanstalk_environment.beanstalk_green.zone_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "weighted_blue" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "${var.environment}.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.beanstalk_blue.cname
    zone_id                = aws_elastic_beanstalk_environment.beanstalk_blue.zone_name
    evaluate_target_health = false
  }

  weight   = 10
}

resource "aws_route53_record" "weighted_green" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "${var.environment}.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.beanstalk_green.cname
    zone_id                = aws_elastic_beanstalk_environment.beanstalk_green.zone_name
    evaluate_target_health = false
  }

  weight   = 10

  set_identifier = "${var.environment}-green"
}

resource "aws_route53_record" "weighted_routing_policy" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "${var.environment}.${var.domain}"
  type    = "A"

  weighted_routing_policy {
    weight   = 10

    set_identifier = "${var.environment}-green"
  }

  alias {
    name                   = aws_elastic_beanstalk_environment.beanstalk_green.cname
    zone_id                = aws_elastic_beanstalk_environment.beanstalk_green.zone_name
    evaluate_target_health = false
  }
}