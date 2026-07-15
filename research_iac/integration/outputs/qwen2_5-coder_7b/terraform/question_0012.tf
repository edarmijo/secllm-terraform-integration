provider "aws" {
  region = "us-west-2"
}

resource "aws_elastic_beanstalk_environment" "blue" {
  name                = "my-app-blue"
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.5.1 running Python 3.8"
}

resource "aws_elastic_beanstalk_environment" "green" {
  name                = "my-app-green"
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.5.1 running Python 3.8"
}

resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_record" "blue" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "myapp.example.com"
  type    = "A"
  ttl     = 300

  weighted_routing_policy {
    weight = 1
  }

  records = [aws_elastic_beanstalk_environment.blue.endpoint]
}

resource "aws_route53_record" "green" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "myapp.example.com"
  type    = "A"
  ttl     = 300

  weighted_routing_policy {
    weight = 1
  }

  records = [aws_elastic_beanstalk_environment.green.endpoint]
}