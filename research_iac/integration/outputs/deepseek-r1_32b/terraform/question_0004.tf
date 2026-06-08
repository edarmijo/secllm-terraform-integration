provider "aws" {
  region = var.region
}

resource "aws_route53_zone" "private" {
  name = "private."
}

resource "aws_route53_zone" "public" {
  name = "public."
}

resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = var.subnet_ids
}

resource "aws_rds_instance" "internal" {
  identifier              = "internal-rds"
  instance_class          = "db.t3.micro"
  engine                  = "mysql"
  publicly_accessible     = false
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.internal.id]
}

resource "aws_rds_instance" "public" {
  identifier              = "public-rds"
  instance_class          = "db.t3.micro"
  engine                  = "mysql"
  publicly_accessible     = true
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.public.id]
}

resource "aws_route53_record" "internal-database" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "database.internal"
  type    = "CNAME"
  ttl     = 300
  records = [aws_rds_instance.internal.endpoint]
}

resource "aws_route53_record" "public-database" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "database.public"
  type    = "A"
  ttl     = 300
  records = [aws_rds_instance.public.endpoint_address]
}

resource "aws_security_group" "internal" {
  name        = "internal-rds-sg"
  description = "Security group for internal RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Replace with your VPC CIDR
  }
}

resource "aws_security_group" "public" {
  name        = "public-rds-sg"
  description = "Security group for public RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Or restrict to specific IPs
  }
}

variable "region" {
  type        = string
  description = "AWS region for deployment"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where resources will be deployed"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the RDS instances"
}