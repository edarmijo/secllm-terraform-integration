provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "blue_green_role" {
  name = "blue-green-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "blue_green_policy" {
  name = "blue-green-policy"
  role = aws_iam_role.blue_green_role.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticbeanstalk:*",
        "route53:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_route53_record_set" "blue_record" {
  name = "example.com"
  type = "A"
  alias {
    name = aws_elastic_beanstalk_environment.blue.dns_name
    zone_id = aws_route53_zone.example_zone.zone_id
  }
}

resource "aws_route53_record_set" "green_record" {
  name = "example.com"
  type = "A"
  alias {
    name = aws_elastic_beanstalk_environment.green.dns_name
    zone_id = aws_route53_zone.example_zone.zone_id
  }
}

resource "aws_route53_weighted_routing_policy" "blue_green_policy" {
  name = "blue-green-policy"

  routing_policy {
    weight = 50
    health_check_id = aws_route53_health_check.blue_green_health_check.id
    priority = 1
  }

  routing_policy {
    weight = 50
    health_check_id = aws_route53_health_check.blue_green_health_check.id
    priority = 2
  }
}

resource "aws_route53_alias_target" "blue_target" {
  name = aws_route53_record_set.blue_record.name
  zone_id = aws_route53_zone.example_zone.zone_id
  evaluate_target_health = false
}

resource "aws_route53_alias_target" "green_target" {
  name = aws_route53_record_set.green_record.name
  zone_id = aws_route53_zone.example_zone.zone_id
  evaluate_target_health = false
}