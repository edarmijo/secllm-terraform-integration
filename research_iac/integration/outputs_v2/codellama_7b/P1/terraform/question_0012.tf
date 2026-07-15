provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "example" {
  name    = "example.com."
  comment = "Example Route53 zone"
}

resource "aws_route53_record" "blue" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "blue.example.com."
  type    = "A"
  ttl     = 60
  records = [aws_elastic_beanstalk_environment.blue.endpoint]
}

resource "aws_route53_record" "green" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "green.example.com."
  type    = "A"
  ttl     = 60
  records = [aws_elastic_beanstalk_environment.green.endpoint]
}

resource "aws_route53_record" "blue-weighted" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "blue.example.com."
  type    = "A"
  ttl     = 60
  records = [aws_elastic_beanstalk_environment.blue.endpoint]
  weighted_routing_policy {
    weight = 1
  }
}

resource "aws_route53_record" "green-weighted" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "green.example.com."
  type    = "A"
  ttl     = 60
  records = [aws_elastic_beanstalk_environment.green.endpoint]
  weighted_routing_policy {
    weight = 1
  }
}

resource "aws_elastic_beanstalk_environment" "blue" {
  name        = "blue-env"
  application = aws_elastic_beanstalk_application.example.name
  tier        = "WebServer"
  version_label = aws_elastic_beanstalk_application_version.example.name
}

resource "aws_elastic_beanstalk_environment" "green" {
  name        = "green-env"
  application = aws_elastic_beanstalk_application.example.name
  tier        = "WebServer"
  version_label = aws_elastic_beanstalk_application_version.example.name
}

resource "aws_elastic_beanstalk_application" "example" {
  name        = "example-app"
  description = "Example Elastic Beanstalk application"
}

resource "aws_elastic_beanstalk_application_version" "example" {
  name         = "example-app-version"
  application  = aws_elastic_beanstalk_application.example.name
  description  = "Example Elastic Beanstalk application version"
  source_bundle = {
    s3_bucket = "my-s3-bucket"
    s3_key    = "path/to/source/bundle.zip"
  }
}