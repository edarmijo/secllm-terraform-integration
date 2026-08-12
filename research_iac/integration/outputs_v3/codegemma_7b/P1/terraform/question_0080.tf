resource "aws_route53_record" "private_record" {
  name = "internal.example53.com"
  type = "A"
  zone = aws_route53_zone.private_zone.zone_id

  alias {
    name = "main"
    zone_id = aws_vpc.main.vpc_id
  }
}

resource "aws_route53_zone" "private_zone" {
  name = "internal.example53.com"
  vpc = aws_vpc.main
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}