provider "aws" {
  region = "us-west-2"
}

resource "aws_route53_zone" "main" {
  name = "example.com"
}

resource "aws_db_instance" "primary" {
  identifier            = "primary-db"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t2.micro"
  allocated_storage     = 20
  username              = "admin"
  password              = "password"
  parameter_group_name  = "default.mysql8.0"
}

resource "aws_db_instance" "replica_1" {
  identifier            = "replica-1-db"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t2.micro"
  allocated_storage     = 20
  username              = "admin"
  password              = "password"
  parameter_group_name  = "default.mysql8.0"
  replication_source_identifier = aws_db_instance.primary.identifier
}

resource "aws_db_instance" "replica_2" {
  identifier            = "replica-2-db"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t2.micro"
  allocated_storage     = 20
  username              = "admin"
  password              = "password"
  parameter_group_name  = "default.mysql8.0"
  replication_source_identifier = aws_db_instance.primary.identifier
}

resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "primary.example.com"
  type    = "A"
  ttl     = 300

  record_set_identifier = "primary-db"

  weighted_routing_policy {
    weight = 1
  }

  alias {
    name                   = aws_db_instance.primary.endpoint
    zone_id                = aws_db_instance.primary.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "replica_1" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "primary.example.com"
  type    = "A"
  ttl     = 300

  record_set_identifier = "replica-1-db"

  weighted_routing_policy {
    weight = 1
  }

  alias {
    name                   = aws_db_instance.replica_1.endpoint
    zone_id                = aws_db_instance.replica_1.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "replica_2" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "primary.example.com"
  type    = "A"
  ttl     = 300

  record_set_identifier = "replica-2-db"

  weighted_routing_policy {
    weight = 1
  }

  alias {
    name                   = aws_db_instance.replica_2.endpoint
    zone_id                = aws_db_instance.replica_2.hosted_zone_id
    evaluate_target_health = true
  }
}