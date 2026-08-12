# Configure a weighted routing policy for splitting users between three replicas of a main db instance
resource "aws_route53_zone" "main" {
  name = "example.com"
}

resource "aws_db_instance" "primary" {
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t2.small"
  availability_zone = "us-west-1a"

  # Other configuration options for the primary db instance
}

resource "aws_db_instance" "replica_us_east" {
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t2.small"
  availability_zone = "us-east-1a"

  # Other configuration options for the replica db instances
}

resource "aws_db_instance" "replica_eu_central" {
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t2.small"
  availability_zone = "eu-central-1a"

  # Other configuration options for the replica db instances
}

resource "aws_db_instance" "replica_ap_southeast" {
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t2.small"
  availability_zone = "ap-southeast-1a"

  # Other configuration options for the replica db instances
}

resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.id
  name    = "example.com"
  type    = "A"
  alias_target {
    hosted_zone_id = aws_elb.primary.zone_id
    dns_name       = aws_elb.primary.dns_name
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "replica_us_east" {
  zone_id = aws_route53_zone.main.id
  name    = "example-us-east.com"
  type    = "A"
  alias_target {
    hosted_zone_id = aws_elb. replica_us_east.zone_id
    dns_name       = aws_elb.replica_us_east.dns_name
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "replica_eu_central" {
  zone_id = aws_route53_zone.main.id
  name    = "example-eu-central.com"
  type    = "A"
  alias_target {
    hosted_zone_id = aws_elb.replica_eu_central.zone_id
    dns_name       = aws_elb.replica_eu_central.dns_name
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "replica_ap_southeast" {
  zone_id = aws_route53_zone.main.id
  name    = "example-ap-southeast.com"
  type    = "A"
  alias_target {
    hosted_zone_id = aws_elb.replica_ap_southeast.zone_id
    dns_name       = aws_elb.replica_ap_southeast.dns_name
    evaluate_target_health = true
  }
}