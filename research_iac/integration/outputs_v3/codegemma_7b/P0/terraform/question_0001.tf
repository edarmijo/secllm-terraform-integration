provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_zone_association" "example" {
  zone_id = aws_route53_zone.example.zone_id
  vpc_id = "vpc-1234567890abcdef0"
}