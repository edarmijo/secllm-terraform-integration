provider "aws" {
  region = "us-west-2"
}

resource "aws_route53_zone" "primary" {
  name = "example.com"
}

resource "aws_route53_record" "location_us" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "*"
  type    = "A"
  alias {
    name                   = aws_lb.us.dns_name
    zone_id                = aws_lb.us.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "location_eu" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "*"
  type    = "A"
  alias {
    name                   = aws_lb.eu.dns_name
    zone_id                = aws_lb.eu.zone_id
    evaluate_target_health = false
  }
}

resource "aws_lb" "us" {
  name               = "example-lb-us"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.us.id]
  subnets            = [aws_subnet.us1.id, aws_subnet.us2.id]

  access_logs {
    enabled          = true
    bucket           = aws_s3_bucket.lb_logs.bucket
    prefix           = "example-lb-us/"
  }
}

resource "aws_lb" "eu" {
  name               = "example-lb-eu"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.eu.id]
  subnets            = [aws_subnet.eu1.id, aws_subnet.eu2.id]

  access_logs {
    enabled          = true
    bucket           = aws_s3_bucket.lb_logs.bucket
    prefix           = "example-lb-eu/"
  }
}

resource "aws_route53_record" "us_routing_policy" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "*"
  type    = "A"
  alias {
    name                   = aws_lb.us.dns_name
    zone_id                = aws_lb.us.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "eu_routing_policy" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "*"
  type    = "A"
  alias {
    name                   = aws_lb.eu.dns_name
    zone_id                = aws_lb.eu.zone_id
    evaluate_target_health = false
  }
}

resource "aws_security_group" "us" {
  name        = "example-sg-us"
  description = "Allow inbound traffic on port 80"
  vpc_id      = aws_vpc.us.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "eu" {
  name        = "example-sg-eu"
  description = "Allow inbound traffic on port 80"
  vpc_id      = aws_vpc.eu.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "us" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_vpc" "eu" {
  cidr_block = "10.1.0.0/16"
}

resource "aws_subnet" "us1" {
  vpc_id     = aws_vpc.us.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "us2" {
  vpc_id     = aws_vpc.us.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_subnet" "eu1" {
  vpc_id     = aws_vpc.eu.id
  cidr_block = "10.1.1.0/24"
}

resource "aws_subnet" "eu2" {
  vpc_id     = aws_vpc.eu.id
  cidr_block = "10.1.2.0/24"
}

resource "aws_s3_bucket" "lb_logs" {
  bucket = "example-lb-logs"
  acl    = "log-delivery-write"

  versioning {
    enabled = true
  }
}