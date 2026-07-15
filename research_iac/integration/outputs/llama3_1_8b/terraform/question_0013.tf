provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "beanstalk_us_west" {
  name        = "ElasticBeanstalkUsWestRole"
  description = "IAM role for Elastic Beanstalk in us-west-2"

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

resource "aws_iam_role" "beanstalk_eu_central" {
  name        = "ElasticBeanstalkEuCentralRole"
  description = "IAM role for Elastic Beanstalk in eu-central-1"

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

resource "aws_iam_role_policy" "beanstalk_us_west" {
  name   = "ElasticBeanstalkUsWestPolicy"
  role   = aws_iam_role.beanstalk_us_west.id
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
        Resource = aws_s3_bucket.beanstalk_us_west.arn
      },
    ]
  })
}

resource "aws_iam_role_policy" "beanstalk_eu_central" {
  name   = "ElasticBeanstalkEuCentralPolicy"
  role   = aws_iam_role.beanstalk_eu_central.id
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
        Resource = aws_s3_bucket.beanstalk_eu_central.arn
      },
    ]
  })
}

resource "aws_elastic_beanstalk_environment" "us_west" {
  name                = "my-env-us-west-2"
  application         = "my-app"
  description         = "Elastic Beanstalk environment in us-west-2"
  tier                = "webserver-medium"
  platform            = "64bit Amazon Linux 2018.03 v2.10.4 running Java 8"
}

resource "aws_elastic_beanstalk_environment" "eu_central" {
  name                = "my-env-eu-central-1"
  application         = "my-app"
  description         = "Elastic Beanstalk environment in eu-central-1"
  tier                = "webserver-medium"
  platform            = "64bit Amazon Linux 2018.03 v2.10.4 running Java 8"
}

resource "aws_s3_bucket" "beanstalk_us_west" {
  bucket = "my-bucket-us-west-2"
}

resource "aws_s3_bucket" "beanstalk_eu_central" {
  bucket = "my-bucket-eu-central-1"
}

resource "aws_route53_zone" "example" {
  name = "example.com."
}

resource "aws_route53_record" "us_west" {
  zone_id = aws_route53_zone.example.id
  name    = "us-west.example.com."
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.us_west.dns_name
    zone_id                = aws_elastic_beanstalk_environment.us_west.zone_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "eu_central" {
  zone_id = aws_route53_zone.example.id
  name    = "eu-central.example.com."
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.eu_central.dns_name
    zone_id                = aws_elastic_beanstalk_environment.eu_central.zone_name
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "example" {
  domain_name       = "example.com."
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "example_validation_us_west" {
  zone_id = aws_route53_zone.example.id
  name    = aws_acm_certificate.example.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.example.domain_validation_options[0].resource_record_type
  records = [aws_acm_certificate.example.validation_record]
  ttl     = "60"
}

resource "aws_route53_record" "example_validation_eu_central" {
  zone_id = aws_route53_zone.example.id
  name    = aws_acm_certificate.example.domain_validation_options[1].resource_record_name
  type    = aws_acm_certificate.example.domain_validation_options[1].resource_record_type
  records = [aws_acm_certificate.example.validation_record]
  ttl     = "60"
}

resource "aws_route53_record" "example_cert_us_west" {
  zone_id = aws_route53_zone.example.id
  name    = "*.us-west.example.com."
  type    = "CNAME"
  alias {
    name                   = aws_acm_certificate.example.arn
    zone_id                = aws_acm_certificate.example.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "example_cert_eu_central" {
  zone_id = aws_route53_zone.example.id
  name    = "*.eu-central.example.com."
  type    = "CNAME"
  alias {
    name                   = aws_acm_certificate.example.arn
    zone_id                = aws_acm_certificate.example.zone_id
    evaluate_target_health = false
  }
}