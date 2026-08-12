provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name    = "example.com."
  comment = "Primary zone for example.com"
}

resource "aws_route53_record" "us" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "us.example.com."
  type    = "A"
  ttl     = 60
  records = ["192.0.2.1"]
}

resource "aws_route53_record" "eu" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "eu.example.com."
  type    = "A"
  ttl     = 60
  records = ["192.0.2.2"]
}

resource "aws_route53_record" "location" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "example.com."
  type    = "A"
  ttl     = 60
  records = [
    for location in ["US", "EU"] : {
      if location == "US" : aws_route53_record.us.name
      else : aws_route53_record.eu.name
    }
  ]
}