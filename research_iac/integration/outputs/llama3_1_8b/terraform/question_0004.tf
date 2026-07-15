provider "aws" {
  region = "us-west-2"
}

resource "aws_route53_zone" "private" {
  name = "private.example.com."
}

resource "aws_route53_zone" "public" {
  name = "example.com."
}

resource "aws_rds_instance" "internal" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  username             = "admin"
  password             = "password"
  db_subnet_group_name = aws_db_subnet_group.main.name
}

resource "aws_rds_instance" "public" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  username             = "admin"
  password             = "password"
  publicly_accessible  = true
  db_subnet_group_name = aws_db_subnet_group.main.name
}

resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = [aws_subnet.private.id, aws_subnet.public.id]
}

resource "aws_route53_record" "internal" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "db.internal.example.com."
  type    = "CNAME"
  ttl     = "30"
  records = ["${aws_rds_instance.internal.endpoint}/"]
}

resource "aws_route53_record" "public" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "db.example.com."
  type    = "CNAME"
  ttl     = "30"
  records = ["${aws_rds_instance.public.endpoint}/"]
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}