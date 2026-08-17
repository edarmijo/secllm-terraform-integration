provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

provider "aws" {
  region = "eu-west-1"
  alias  = "eu-west-1"
}

resource "aws_route53_zone" "example" {
  name = "example.com"

  provider = aws.us-east-1
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.id
  name    = "www"
  type    = "A"
  alias_target {
    hosted_zone_id = "Z26RNL4JYFTOTI"
    dns_name       = "elasticbeanstalk-us-east-1-123456789012.elb.us-east-1.amazonaws.com"
    evaluate_target_health = false
  }

  provider = aws.us-east-1
}

resource "aws_route53_zone" "example" {
  name = "example.com"

  provider = aws.eu-west-1
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.id
  name    = "www"
  type    = "A"
  alias_target {
    hosted_zone_id = "Z26RNL4JYFTOTI"
    dns_name       = "elasticbeanstalk-eu-west-1-123456789012.elb.eu-west-1.amazonaws.com"
    evaluate_target_health = false
  }

  provider = aws.eu-west-1
}