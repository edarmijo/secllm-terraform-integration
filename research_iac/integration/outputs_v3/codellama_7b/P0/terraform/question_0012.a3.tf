provider "aws" {
  region = "us-east-1"
}

resource "aws_elastic_beanstalk_environment" "blue" {
  name        = "blue"
  application = "my-application"
  tier        = "WebServer"
}

resource "aws_elastic_beanstalk_environment" "green" {
  name        = "green"
  application = "my-application"
  tier        = "WebServer"
}

resource "aws_route53_record" "blue" {
  zone_id = "Z1234567890ABCDEFGHIJKL"
  name    = "example.com."
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.blue.cname
    zone_id                = aws_elastic_beanstalk_environment.blue.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "green" {
  zone_id = "Z1234567890ABCDEFGHIJKL"
  name    = "example.com."
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.green.cname
    zone_id                = aws_elastic_beanstalk_environment.green.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "blue-weighted" {
  zone_id = "Z1234567890ABCDEFGHIJKL"
  name    = "example.com."
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.blue.cname
    zone_id                = aws_elastic_beanstalk_environment.blue.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "green-weighted" {
  zone_id = "Z1234567890ABCDEFGHIJKL"
  name    = "example.com."
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.green.cname
    zone_id                = aws_elastic_beanstalk_environment.green.zone_id
    evaluate_target_health = true
  }
}