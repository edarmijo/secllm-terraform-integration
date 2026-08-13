provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "private_zone" {
  name = "internal.example53.com"

  vpc {
    vpc_id = aws_vpc.main.id
  }
}

resource "aws_route53_record" "example_record" {
  name    = "example.internal.example53.com"
  type    = "A"
  alias {
    name = aws_route53_zone.private_zone.name
    zone_id = aws_route53_zone.private_zone.zone_id
  }
}