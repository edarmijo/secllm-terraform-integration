provider "aws" {
  alias   = "us_west"
  region  = "us-west-2"
}

provider "aws" {
  alias   = "eu_central"
  region  = "eu-central-1"
}

resource "aws_elastic_beanstalk_environment" "us_west" {
  provider            = aws.us_west
  name                = "us_west"
  application         = "my_app"
  solution_stack_name = "64bit Amazon Linux 2 v3.4.7 running Node.js 14"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.us_west.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
}

resource "aws_elastic_beanstalk_environment" "eu_central" {
  provider            = aws.eu_central
  name                = "eu_central"
  application         = "my_app"
  solution_stack_name = "64bit Amazon Linux 2 v3.4.7 running Node.js 14"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eu_central.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
}

resource "aws_route53_record" "alias_us_west" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "us-west.example.com"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.us_west.cname
    zone_id                = aws_elastic_beanstalk_environment.us_west.load_balancer_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "alias_eu_central" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "eu-central.example.com"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.eu_central.cname
    zone_id                = aws_elastic_beanstalk_environment.eu_central.load_balancer_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "geolocation_us_west" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "example.com"
  type    = "A"

  set_identifier = "US West"

  geolocation {
    country_code = "*"
    continent    = "NA"
  }

  alias {
    name                   = aws_elastic_beanstalk_environment.us_west.cname
    zone_id                = aws_elastic_beanstalk_environment.us_west.load_balancer_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "geolocation_eu_central" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "example.com"
  type    = "A"

  set_identifier = "EU Central"

  geolocation {
    country_code = "*"
    continent    = "EU"
  }

  alias {
    name                   = aws_elastic_beanstalk_environment.eu_central.cname
    zone_id                = aws_elastic_beanstalk_environment.eu_central.load_balancer_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "default" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "example.com"
  type    = "A"

  set_identifier = "Default"

  alias {
    name                   = aws_elastic_beanstalk_environment.us_west.cname
    zone_id                = aws_elastic_beanstalk_environment.us_west.load_balancer_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_zone" "primary" {
  name = "example.com"
}

resource "aws_iam_instance_profile" "us_west" {
  provider = aws.us_west
  name     = "us_west_instance_profile"
  role     = aws_iam_role.us_west.name
}

resource "aws_iam_instance_profile" "eu_central" {
  provider = aws.eu_central
  name     = "eu_central_instance_profile"
  role     = aws_iam_role.eu_central.name
}

resource "aws_iam_role" "us_west" {
  provider           = aws.us_west
  name               = "us_west_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role" "eu_central" {
  provider           = aws.eu_central
  name               = "eu_central_role"
  assume_role_policy = data.aws_iam_policy_document.assume_route53.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}