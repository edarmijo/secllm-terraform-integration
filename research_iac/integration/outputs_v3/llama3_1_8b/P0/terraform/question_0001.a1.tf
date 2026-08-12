provider "aws" {
  region = "us-west-2"
}

resource "aws_route53_zone_association" "example" {
  zone_id = aws_route53_zone.example.id
  vpc_id  = aws_vpc.main.id
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_route53_zone" "example" {
  name = "example.com"
}