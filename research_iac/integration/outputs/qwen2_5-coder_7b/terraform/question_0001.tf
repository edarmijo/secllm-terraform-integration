provider "aws" {
  region = "us-west-2"
}

resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_route53_delegation_set" "example" {
  caller_reference = "${timestamp()}"
}

resource "aws_route53_zone_association" "example" {
  zone_id          = aws_route53_zone.example.zone_id
  vpc_id           = aws_vpc.example.id
  delegation_set_id = aws_route53_delegation_set.example.id
}