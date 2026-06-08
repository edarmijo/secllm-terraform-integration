provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "route53_zone_association" {
  name = "route53-zone-association-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "route53.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_route53_zone_association" "example" {
  hosted_zone_id = "Z123456789EXAMPLE"
  vpc_id         = "vpc-12345678"
  vpc_region     = var.region
}