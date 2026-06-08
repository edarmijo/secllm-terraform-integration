provider "aws" {
  region = "us-west-1"
  alias  = "main"
}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east"
}

provider "aws" {
  region = "eu-central-1"
  alias  = "eu-central"
}

provider "aws" {
  region = "ap-southeast-1"
  alias  = "ap-southeast"
}

resource "aws_rds_instance" "primary" {
  provider            = aws.main
  engine              = var.db_engine
  engine_version      = var.db_engine_version
  instance_class      = var.db_instance_class
  identifier          = "primary"
  db_name             = var.db_name
  username            = var.db_username
  password            = var.db_password
}

resource "aws_rds_instance" "replica_us_east" {
  provider            = aws.us-east
  engine              = var.db_engine
  engine_version      = var.db_engine_version
  instance_class      = var.db_instance_class
  identifier          = "replica_us_east"
  db_name             = var.db_name
  username            = var.db_username
  password            = var.db_password
  source_instance_id  = aws_rds_instance.primary.id
}

resource "aws_rds_instance" "replica_eu_central" {
  provider            = aws.eu-central
  engine              = var.db_engine
  engine_version      = var.db_engine_version
  instance_class      = var.db_instance_class
  identifier          = "replica_eu_central"
  db_name             = var.db_name
  username            = var.db_username
  password            = var.db_password
  source_instance_id  = aws_rds_instance.primary.id
}

resource "aws_rds_instance" "replica_ap_southeast" {
  provider            = aws.ap-southeast
  engine              = var.db_engine
  engine_version      = var.db_engine_version
  instance_class      = var.db_instance_class
  identifier          = "replica_ap_southeast"
  db_name             = var.db_name
  username            = var.db_username
  password            = var.db_password
  source_instance_id  = aws_rds_instance.primary.id
}

resource "aws_route53_zone" "main" {
  provider    = aws.main
  name        = "main."
  comment     = "Main zone for weighted routing"
}

resource "aws_route53_record" "primary" {
  provider         = aws.main
  zone_id          = aws_route53_zone.main.zone_id
  name             = "db.${aws_route53_zone.main.name}"
  type             = "A"
  ttl              = 300
  weight           = 100
  records          = [aws_rds_instance.primary.public_ip]
}

resource "aws_route53_record" "replica_us_east" {
  provider         = aws.us-east
  zone_id          = aws_route53_zone.main.zone_id
  name             = "db.${aws_route53_zone.main.name}"
  type             = "A"
  ttl              = 300
  weight           = 50
  records          = [aws_rds_instance.replica_us_east.public_ip]
}

resource "aws_route53_record" "replica_eu_central" {
  provider         = aws.eu-central
  zone_id          = aws_route53_zone.main.zone_id
  name             = "db.${aws_route53_zone.main.name}"
  type             = "A"
  ttl              = 300
  weight           = 30
  records          = [aws_rds_instance.replica_eu_central.public_ip]
}

resource "aws_route53_record" "replica_ap_southeast" {
  provider         = aws.ap-southeast
  zone_id          = aws_route53_zone.main.zone_id
  name             = "db.${aws_route53_zone.main.name}"
  type             = "A"
  ttl              = 300
  weight           = 20
  records          = [aws_rds_instance.replica_ap_southeast.public_ip]
}