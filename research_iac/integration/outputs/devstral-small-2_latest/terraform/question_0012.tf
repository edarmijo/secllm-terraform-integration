provider "aws" {
  region = "us-east-1"
}

resource "aws_elastic_beanstalk_environment" "blue" {
  name                = "blue"
  application         = "my-app"
  solution_stack_name = "64bit Amazon Linux 2 v3.4.7 running Node.js 14"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb.arn
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
}

resource "aws_elastic_beanstalk_environment" "green" {
  name                = "green"
  application         = "my-app"
  solution_stack_name = "64bit Amazon Linux 2 v3.4.7 running Node.js 14"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb.arn
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
}

resource "aws_route53_record" "blue" {
  zone_id = "Z1234567890ABCDEFGHIJKL"
  name    = "my-app.example.com"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.blue.cname
    zone_id                = aws_elastic_beanstalk_environment.blue.load_balancer_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "green" {
  zone_id = "Z1234567890ABCDEFGHIJKL"
  name    = "my-app.example.com"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.green.cname
    zone_id                = aws_elastic_beanstalk_environment.green.load_balancer_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "weighted" {
  zone_id = "Z1234567890ABCDEFGHIJKL"
  name    = "my-app.example.com"
  type    = "A"

  set_identifier = "blue-green-weight"

  weighted_routing_policy {
    weight = 50
  }

  alias {
    name                   = aws_route53_record.blue.fqdn
    zone_id                = aws_route53_record.blue.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_iam_instance_profile" "eb" {
  name = "eb-instance-profile"
  role = aws_iam_role.eb.name
}

resource "aws_iam_role" "eb" {
  name = "eb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eb" {
  role       = aws_iam_role.eb.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}