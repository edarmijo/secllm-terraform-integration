provider "aws" {
  region = "us-west-2"
}

resource "aws_route53_zone_association" "example" {
  zone_id = aws_route53_zone.example.id
  vpc_id  = aws_vpc.example.id
}