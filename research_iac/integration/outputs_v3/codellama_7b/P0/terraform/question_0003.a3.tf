provider "aws" {
  region = "us-west-1"
}

resource "aws_route53_zone" "main" {
  name    = "example.com."
  comment = "Main zone for the application"
}

resource "aws_db_instance" "primary" {
  identifier           = "primary"
  allocated_storage    = 10
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "root"
  password             = "password"
  parameter_group_name = "default.mysql5.7"
  multi_az             = true
  publicly_accessible  = true
}

resource "aws_db_instance" "replica_us_east" {
  provider            = aws.us-east
  identifier          = "replica_us_east"
  allocated_storage   = 10
  engine              = "mysql"
  instance_class      = "db.t2.micro"
  name                = "mydb"
  username            = "root"
  password            = "password"
  parameter_group_name = "default.mysql5.7"
  multi_az            = true
  publicly_accessible = true
}

resource "aws_db_instance" "replica_eu_central" {
  provider            = aws.eu-central
  identifier          = "replica_eu_central"
  allocated_storage   = 10
  engine              = "mysql"
  instance_class      = "db.t2.micro"
  name                = "mydb"
  username            = "root"
  password            = "password"
  parameter_group_name = "default.mysql5.7"
  multi_az            = true
  publicly_accessible = true
}

resource "aws_db_instance" "replica_ap_southeast" {
  provider            = aws.ap-southeast
  identifier          = "replica_ap_southeast"
  allocated_storage   = 10
  engine              = "mysql"
  instance_class      = "db.t2.micro"
  name                = "mydb"
  username            = "root"
  password            = "password"
  parameter_group_name = "default.mysql5.7"
  multi_az            = true
  publicly_accessible = true
}

resource "aws_route53_record" "weighted_routing" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com."
  type    = "A"
  ttl     = "60"
  records = [
    aws_db_instance.primary.address,
    aws_db_instance.replica_us_east.address,
    aws_db_instance.replica_eu_central.address,
    aws_db_instance.replica_ap_southeast.address,
  ]
}