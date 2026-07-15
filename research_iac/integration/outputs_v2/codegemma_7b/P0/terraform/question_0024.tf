provider "aws" {
  region = "us-east-1"
  profile = "eb_ec2_profile1"
}

resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "www.example.com"
  type    = "A"
  alias {
    name = "myenv.us-east-1.elasticbeanstalk.com"
    zone_id = "Z2FDTNDATAQYW2"
  }
}

resource "aws_route53_alias" "db_alias" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "db.example.com"
  alias {
    name = "myapp_db.us-east-1.rds.amazonaws.com"
    zone_id = "Z2FDTNDATAQYW2"
  }
}