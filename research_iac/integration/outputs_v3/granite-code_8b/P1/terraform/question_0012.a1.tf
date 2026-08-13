# Configure Blue/Green deployment with Route53 resources
resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_record" "blue" {
  zone_id = aws_route53_zone.example.id
  name    = "blue.example.com"
  type    = "A"

  alias_target {
    hosted_zone_id = aws_elastic_beanstalk_environment.blue.hosted_zone_id
    dns_name       = aws_elastic_beanstalk_environment.blue.dns_name
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "green" {
  zone_id = aws_route53_zone.example.id
  name    = "green.example.com"
  type    = "A"

  alias_target {
    hosted_zone_id = aws_elastic_beanstalk_environment.green.hosted_zone_id
    dns_name       = aws_elastic_beanstalk_environment.green.dns_name
    evaluate_target_health = true
  }
}