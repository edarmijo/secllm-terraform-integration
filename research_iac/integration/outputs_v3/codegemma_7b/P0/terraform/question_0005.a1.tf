provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "main" {
  name = "example.com"
}

resource "aws_route53_record_set" "db_instances" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "db.example.com"
  type    = "CNAME"

  alias {
    name = "primary.example.com"
    zone_id = "PRIMARY_DB_ZONE_ID"
  }

  alias {
    name = "replica-1.example.com"
    zone_id = "REPLICA_1_DB_ZONE_ID"
  }

  alias {
    name = "replica-2.example.com"
    zone_id = "REPLICA_2_DB_ZONE_ID"
  }
}

resource "aws_route53_weighted_target" "db_instance_1" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "replica-1.example.com"
  weight  = 50
}

resource "aws_route53_weighted_target" "db_instance_2" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "replica-2.example.com"
  weight  = 50
}

resource "aws_route53_weighted_routing_policy" "db_routing_policy" {
  name = "db_routing_policy"
  description = "Weighted routing policy for db instances"

  health_check_id = "PRIMARY_DB_HEALTH_CHECK_ID"

  target {
    target_id = aws_route53_weighted_target.db_instance_1.id
  }

  target {
    target_id = aws_route53_weighted_target.db_instance_2.id
  }
}

resource "aws_route53_record_set" "weighted_routing" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "db.example.com"
  type    = "CNAME"

  routing_policy {
    type = "weighted"
    weight = 50
    policy_name = aws_route53_weighted_routing_policy.db_routing_policy.name
  }
}