provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "main" {
  name = "example.com"
}

resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "db.example.com"
  type    = "CNAME"
  alias {
    name = aws_db_instance.primary.endpoint
  }
}

resource "aws_route53_record" "replica-1" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "db-replica-1.example.com"
  type    = "CNAME"
  alias {
    name = aws_db_instance.replica-1.endpoint
  }
}

resource "aws_route53_record" "replica-2" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "db-replica-2.example.com"
  type    = "CNAME"
  alias {
    name = aws_db_instance.replica-2.endpoint
  }
}

resource "aws_route53_weighted_target" "replica-1" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "replica-1"
  weight  = 50
  type    = "A"
  target {
    id = aws_db_instance.replica-1.private_ip
  }
}

resource "aws_route53_weighted_target" "replica-2" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "replica-2"
  weight  = 50
  type    = "A"
  target {
    id = aws_db_instance.replica-2.private_ip
  }
}

resource "aws_route53_weighted_routing_policy" "weighted-routing" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "weighted-routing"
  health_check_id = aws_route53_health_check.db.id
  routing_policy {
    type = "weighted"
    weight_target_name = aws_route53_weighted_target.replica-1.name
    weight_target_name = aws_route53_weighted_target.replica-2.name
  }
}

resource "aws_route53_alias_target" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "db.example.com"
  type    = "CNAME"
  alias {
    name = aws_route53_weighted_routing_policy.weighted-routing.name
  }
}