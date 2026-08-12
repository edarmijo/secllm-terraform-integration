resource "aws_route_53_record" "non-alias" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "internal.example53.com."
  type    = "A"
  alias   = false
  ttl     = 60
  records = [aws_vpc.main.cidr_block]
}

resource "aws_route53_zone" "private_zone" {
  name     = "internal.example53.com."
  vpc_id   = aws_vpc.main.id
  comment  = "Private DNS zone for internal.example53.com"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "Main VPC"
  }
}