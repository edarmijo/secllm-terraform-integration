provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_secretsmanager_secret" "route53_secret" {
  name        = "${var.domain_name}-route53-secret"
  description = "Route 53 secret for ${var.domain_name}"
}

resource "aws_secretsmanager_secret_version" "route53_secret_version" {
  secret_id     = aws_secretsmanager_secret.route53_secret.id
  secret_string = jsonencode({
    AWS_ACCESS_KEY_ID = var.aws_access_key_id
    AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
  })
}

resource "aws_route53_zone" "this" {
  name              = var.domain_name
  delegation_set_id = aws_route53_delegation_set.this.id
}

resource "aws_route53_delegation_set" "this" {
  name           = "${var.domain_name}."
  caller_reference = data.aws_caller_identity.current.account_id
}

resource "aws_route53_record" "ipv6_address" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "AAAA"
  ttl     = "300"
  records = [var.ipv6_address]
}

resource "aws_security_group" "this" {
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "${var.domain_name}-vpc"
    Environment = var.environment
  }
}