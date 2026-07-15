provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Main VPC"
  }
}

resource "aws_route53_zone" "private_zone" {
  name = "internal.example53.com."

  vpc {
    id = aws_vpc.main.id
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "non_alias_record" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "example-record.internal.example53.com."
  type    = "A"

  alias {
    name                   = aws_vpc.main.id
    zone_id                = aws_route53_zone.private_zone.zone_id
    evaluate_target_health = false
  }
}