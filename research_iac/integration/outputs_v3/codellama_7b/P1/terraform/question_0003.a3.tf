provider "aws" {
  region = "us-west-1"
}

variable "db_password" {
  type        = string
  description = "The password for the database."
  default     = "your_default_value"
}

resource "aws_route53_zone" "main" {
  name    = "example.com."
  comment = "Main zone for the application"
}

resource "aws_db_instance" "primary" {
  identifier           = "primary-db"
  allocated_storage    = 10
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "root"
  password             = var.db_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_db_instance" "replica_us_east" {
  identifier           = "replica-us-east-db"
  allocated_storage    = 10
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "root"
  password             = var.db_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_db_instance" "replica_eu_central" {
  identifier           = "replica-eu-central-db"
  allocated_storage    = 10
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "root"
  password             = var.db_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_db_instance" "replica_ap_southeast" {
  identifier           = "replica-ap-southeast-db"
  allocated_storage    = 10
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "root"
  password             = var.db_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com."
  type    = "A"
  ttl     = 60
  records = [aws_db_instance.primary.address]
}

resource "aws_route53_record" "replica_us_east" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com."
  type    = "A"
  ttl     = 60
  records = [aws_db_instance.replica_us_east.address]
}

resource "aws_route53_record" "replica_eu_central" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com."
  type    = "A"
  ttl     = 60
  records = [aws_db_instance.replica_eu_central.address]
}

resource "aws_route53_record" "replica_ap_southeast" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com."
  type    = "A"
  ttl     = 60
  records = [aws_db_instance.replica_ap_southeast.address]
}