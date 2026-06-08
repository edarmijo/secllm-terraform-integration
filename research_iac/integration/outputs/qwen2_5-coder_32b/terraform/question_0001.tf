provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "route53_association_role" {
  name = "Route53AssociationRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "route53.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_route53_zone" "example" {
  name = "example.com."
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_route53_vpc_association_authorization" "example" {
  vpc_id  = aws_vpc.example.id
  zone_id = aws_route53_zone.example.zone_id
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "www"
  type    = "A"
  ttl     = 300

  records = ["192.0.2.1"]
}