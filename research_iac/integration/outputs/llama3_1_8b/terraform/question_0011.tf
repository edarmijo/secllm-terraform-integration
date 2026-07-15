provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "eb_ec2_role" {
  name        = "eb-ec2-role"
  description = "Role for Elastic Beanstalk environment"

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

resource "aws_iam_role_policy" "eb_ec2_policy" {
  name   = "eb-ec2-policy"
  role   = aws_iam_role.eb_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.eb_bucket.arn
      },
    ]
  })
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb-ec2-profile"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_elastic_beanstalk_environment" "eb_env" {
  name                = "eb-env"
  application         = aws_elastic_beanstalk_application.myapp.name
  tier                = "webserver"
  environment_name    = "dev"
  solution_stack_name = "64bit Amazon Linux 2 v3.1.0 running Node.js"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", aws_subnet.default.*.id)
  }
}

resource "aws_elastic_beanstalk_application" "myapp" {
  name        = "myapp"
  description = "My Elastic Beanstalk application"
}

resource "aws_s3_bucket" "eb_bucket" {
  bucket = "examplebucket-${random_string.random.id}"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_s3_object" "examplebucket_object" {
  bucket = aws_s3_bucket.eb_bucket.id
  key    = "index.html"
  content = "Hello, World!"
}

resource "aws_route53_zone" "main" {
  name = "example.com."
}

resource "aws_route53_record" "main" {
  zone_id = aws_route53_zone.main.zone_id
  name    = aws_elastic_beanstalk_environment.eb_env.name
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.eb_env.endpoint_url
    zone_id                = aws_elastic_beanstalk_environment.eb_env.zone_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "version" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "${aws_elastic_beanstalk_environment.eb_env.name}.${aws_elastic_beanstalk_application.myapp.name}"
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.eb_env.endpoint_url
    zone_id                = aws_elastic_beanstalk_environment.eb_env.zone_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "object" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "${aws_s3_bucket.eb_bucket.bucket}.s3.amazonaws.com"
  type    = "CNAME"
  alias {
    name                   = aws_s3_bucket.eb_bucket.website_endpoint
    zone_id                = aws_s3_bucket.eb_bucket.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_elastic_beanstalk_application_version" "version" {
  application_name = aws_elastic_beanstalk_application.myapp.name
  version_label    = "v1"
}