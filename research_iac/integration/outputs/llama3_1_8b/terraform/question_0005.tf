provider "aws" {
  region = "us-west-2"
}

data "aws_route53_zone" "main" {
  name = "main.com."
}

resource "aws_db_instance" "primary" {
  identifier           = "primary-db-instance"
  instance_class       = "db.t3.micro"
  engine               = "mysql"
  username             = "admin"
  password             = "password123"
  skip_final_snapshot  = true
}

resource "aws_db_instance" "replica-1" {
  identifier           = "replica-1-db-instance"
  instance_class       = "db.t3.micro"
  engine               = "mysql"
  username             = "admin"
  password             = "password123"
  skip_final_snapshot  = true
  replica_identifier   = aws_db_instance.primary.identifier
}

resource "aws_db_instance" "replica-2" {
  identifier           = "replica-2-db-instance"
  instance_class       = "db.t3.micro"
  engine               = "mysql"
  username             = "admin"
  password             = "password123"
  skip_final_snapshot  = true
  replica_identifier   = aws_db_instance.primary.identifier
}

resource "aws_route53_record" "primary" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "db.main.com."
  type    = "CNAME"
  alias {
    name                   = aws_db_instance.primary.endpoint
    zone_id                = aws_db_instance.primary.endpoint_domain
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "replica-1" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "db-replica-1.main.com."
  type    = "CNAME"
  alias {
    name                   = aws_db_instance.replica-1.endpoint
    zone_id                = aws_db_instance.replica-1.endpoint_domain
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "replica-2" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "db-replica-2.main.com."
  type    = "CNAME"
  alias {
    name                   = aws_db_instance.replica-2.endpoint
    zone_id                = aws_db_instance.replica-2.endpoint_domain
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "weighted-routing-policy" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "db.main.com."
  type    = "A"
  alias {
    name                   = aws_route53_record.primary.name
    zone_id                = aws_route53_record.primary.zone_id
    evaluate_target_health = false
  }
  weighted_routing_policy {
    weight = 10
    region  = "us-west-2"
  }
}

resource "aws_route53_record" "weighted-routing-policy-replica-1" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "db-replica-1.main.com."
  type    = "A"
  alias {
    name                   = aws_route53_record.replica-1.name
    zone_id                = aws_route53_record.replica-1.zone_id
    evaluate_target_health = false
  }
  weighted_routing_policy {
    weight = 5
    region  = "us-west-2"
  }
}

resource "aws_route53_record" "weighted-routing-policy-replica-2" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "db-replica-2.main.com."
  type    = "A"
  alias {
    name                   = aws_route53_record.replica-2.name
    zone_id                = aws_route53_record.replica-2.zone_id
    evaluate_target_health = false
  }
  weighted_routing_policy {
    weight = 5
    region  = "us-west-2"
  }
}