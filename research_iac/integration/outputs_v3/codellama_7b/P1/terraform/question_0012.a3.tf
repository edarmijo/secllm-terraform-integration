resource "aws_elastic_beanstalk_application" "example" {
  name        = "example-app"
}

resource "aws_elastic_beanstalk_environment" "blue" {
  name                = "blue"
  application         = aws_elastic_beanstalk_application.example.name
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.10.9 running Node.js 10"
}

resource "aws_elastic_beanstalk_environment" "green" {
  name                = "green"
  application         = aws_elastic_beanstalk_application.example.name
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.10.9 running Node.js 10"
}

resource "aws_route53_record" "blue" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "example.com."
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.blue.endpoint_url
    zone_id                = aws_elastic_beanstalk_environment.blue.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "green" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "example.com."
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.green.endpoint_url
    zone_id                = aws_elastic_beanstalk_environment.green.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "weighted" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "example.com."
  type    = "A"
  alias {
    name                   = "blue"
    zone_id                = aws_elastic_beanstalk_environment.blue.zone_id
    evaluate_target_health = true
  }
  weighted_routing_policy {
    weight = 50
  }
}