provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_route53_zone" "example" {
  name = "example.com."
}

resource "aws_route53_zone_association" "example" {
  vpc_id     = aws_vpc.example.id
  zone_id    = aws_route53_zone.example.id
}