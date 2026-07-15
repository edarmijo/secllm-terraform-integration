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

resource "aws_db_instance" "primary" {
  provider             = aws.main
  identifier           = "main-db-instance"
  instance_class       = "db.t3.micro"
  engine               = "mysql"
  username             = "admin"
  password             = "password"
  allocated_storage    = 20
  vpc_security_group_ids = ["sg-12345678"]
}

resource "aws_db_instance" "replica_us_east" {
  provider             = aws.us-east
  identifier           = "replica-us-east"
  instance_class       = "db.t3.micro"
  engine               = "mysql"
  username             = "admin"
  password             = "password"
  allocated_storage    = 20
  vpc_security_group_ids = ["sg-12345678"]
  source_db_instance_identifier = aws_db_instance.primary.identifier
}

resource "aws_db_instance" "replica_eu_central" {
  provider             = aws.eu-central
  identifier           = "replica-eu-central"
  instance_class       = "db.t3.micro"
  engine               = "mysql"
  username             = "admin"
  password             = "password"
  allocated_storage    = 20
  vpc_security_group_ids = ["sg-12345678"]
  source_db_instance_identifier = aws_db_instance.primary.identifier
}

resource "aws_db_instance" "replica_ap_southeast" {
  provider             = aws.ap-southeast
  identifier           = "replica-ap-southeast"
  instance_class       = "db.t3.micro"
  engine               = "mysql"
  username             = "admin"
  password             = "password"
  allocated_storage    = 20
  vpc_security_group_ids = ["sg-12345678"]
  source_db_instance_identifier = aws_db_instance.primary.identifier
}

resource "aws_route53_zone" "main" {
  name = "example.com."
}

resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "primary.example.com"
  type    = "A"
  ttl     = 300

  records = [
    aws_db_instance.primary.address,
    aws_db_instance.replica_us_east.address,
    aws_db_instance.replica_eu_central.address,
    aws_db_instance.replica_ap_southeast.address
  ]
}

resource "aws_route53_record" "replicas" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "replica.example.com"
  type    = "A"
  ttl     = 300

  records = [
    aws_db_instance.primary.address,
    aws_db_instance.replica_us_east.address,
    aws_db_instance.replica_eu_central.address,
    aws_db_instance.replica_ap_southeast.address
  ]

  set_identifier = "replicas"
  weight         = 1
}