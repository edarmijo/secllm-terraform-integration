provider "aws" {
  alias  = "main"
  region = "us-west-1"
}

provider "aws" {
  alias  = "us-east"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu-central"
  region = "eu-central-1"
}

provider "aws" {
  alias  = "ap-southeast"
  region = "ap-southeast-1"
}

resource "aws_route53_zone" "main" {
  name = "example.com"
}

resource "aws_db_instance" "primary" {
  provider = aws.main

  identifier           = "primary"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.small"
  availability_zone    = "us-west-1a"
  backup_retention_period = 7
}

resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"

  alias_target {
    hosted_zone_id = aws_elb.primary.zone_id
    dns_name       = aws_elb.primary.dns_name
    evaluate_target_health = false
  }
}

resource "aws_db_instance" "replica_us_east" {
  provider = aws.us-east

  identifier           = "replica_us_east"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.small"
  availability_zone    = "us-east-1a"

  replicate_source_db = aws_db_instance.primary.id
}

resource "aws_route53_record" "replica_us_east" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"

  alias_target {
    hosted_zone_id = aws_elb.primary.zone_id
    dns_name       = aws_elb.primary.dns_name
    evaluate_target_health = false
  }
}

resource "aws_db_instance" "replica_eu_central" {
  provider = aws.eu-central

  identifier           = "replica_eu_central"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.small"
  availability_zone    = "eu-central-1a"

  replicate_source_db = aws_db_instance.primary.id
}

resource "aws_route53_record" "replica_eu_central" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"

  alias_target {
    hosted_zone_id = aws_elb.primary.zone_id
    dns_name       = aws_elb.primary.dns_name
    evaluate_target_health = false
  }
}

resource "aws_db_instance" "replica_ap_southeast" {
  provider = aws.ap-southeast

  identifier           = "replica_ap_southeast"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.small"
  availability_zone    = "ap-southeast-1a"

  replicate_source_db = aws_db_instance.primary.id
}

resource "aws_route53_record" "replica_ap_southeast" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"

  alias_target {
    hosted_zone_id = aws_elb.primary.zone_id
    dns_name       = aws_elb.primary.dns_name
    evaluate_target_health = false
  }
}