resource "aws_route53_zone" "main" {
  name = "example.com"
}

resource "aws_db_instance" "primary" {
  identifier           = "primary"
  engine               = "mysql"
  instance_class       = "db.t2.small"
  availability_zone    = "us-east-1a"
  multi_az             = true
  storage_type         = "gp2"
  backup_Retention_period = 7
}

resource "aws_db_instance" "replica-1" {
  identifier           = "replica-1"
  engine               = "mysql"
  instance_class       = "db.t2.small"
  availability_zone    = "us-east-1b"
  multi_az             = true
  storage_type         = "gp2"
  backup_retention_period = 7
}

resource "aws_db_instance" "replica-2" {
  identifier           = "replica-2"
  engine               = "mysql"
  instance_class       = "db.t2.small"
  availability_zone    = "us-east-1c"
  multi_az             = true
  storage_type         = "gp2"
  backup_retention_period = 7
}

resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "primary"
  type    = "A"
  alias_target {
    hosted_zone_id = aws_db_instance.primary.reader_endpoint
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "replica-1" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "replica-1"
  type    = "A"
  alias_target {
    hosted_zone_id = aws_db_instance.primary.reader_endpoint
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "replica-2" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "replica-2"
  type    = "A"
  alias_target {
    hosted_zone_id = aws_db_instance.primary.reader_endpoint
    evaluate_target_health = true
  }
}