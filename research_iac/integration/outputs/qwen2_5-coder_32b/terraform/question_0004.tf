provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "route53_resolver" {
  name = "Route53ResolverRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "route53resolver.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_route53_resolver_rule" "internal" {
  domain_name = "private.example.com"
  rule_type   = "FORWARD"

  resolver_endpoint_id = aws_route53_resolver_endpoint.internal.id
  target_ips           = [{ ip = "10.0.0.1" }]
}

resource "aws_route53_resolver_rule" "public" {
  domain_name = "public.example.com"
  rule_type   = "FORWARD"

  resolver_endpoint_id = aws_route53_resolver_endpoint.public.id
  target_ips           = [{ ip = "203.0.113.1" }]
}

resource "aws_route53_resolver_endpoint" "internal" {
  direction = "INBOUND"
  security_group_ids = [aws_security_group.internal_sg.id]
  ip_addresses = [
    { subnet_id = aws_subnet.main.id }
  ]
}

resource "aws_route53_resolver_endpoint" "public" {
  direction = "INBOUND"
  security_group_ids = [aws_security_group.public_sg.id]
  ip_addresses = [
    { subnet_id = aws_subnet.main.id }
  ]
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_security_group" "internal_sg" {
  name   = "internal-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "public_sg" {
  name   = "public-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}