terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Private Subnets for Internal DB
resource "aws_subnet" "private" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
}

# Public Subnets for Public DB
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 2)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Route 53 Private Hosted Zone
resource "aws_route53_zone" "private" {
  name = "internal.${var.domain_suffix}"
  vpc {
    vpc_id = aws_vpc.main.id
  }
}

# Route 53 Public Hosted Zone
resource "aws_route53_zone" "public" {
  name = "public.${var.domain_suffix}"
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = aws_subnet.private[*].id
}

# Internal RDS Instance
resource "aws_db_instance" "internal" {
  identifier = "internal"
  engine         = "postgres"
  engine_version = "15.3"
  instance_class = "db.t3.micro"
  allocated_storage     = 20
  storage_type          = "gp2"
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.internal.id]
  publicly_accessible   = false
  skip_final_snapshot   = true
}

# Public RDS Instance
resource "aws_db_instance" "public" {
  identifier = "public"
  engine         = "postgres"
  engine_version = "15.3"
  instance_class = "db.t3.micro"
  allocated_storage     = 20
  storage_type          = "gp2"
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.public.id]
  publicly_accessible   = true
  skip_final_snapshot   = true
}

# Security Groups
resource "aws_security_group" "internal" {
  name        = "internal-db-sg"
  description = "Allow internal DB access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
}

resource "aws_security_group" "public" {
  name        = "public-db-sg"
  description = "Allow public DB access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Route 53 Records
resource "aws_route53_record" "internal" {
  name    = "db.internal"
  type    = "A"
  zone_id = aws_route53_zone.private.id
  records = [aws_db_instance.internal.endpoint]
}

resource "aws_route53_record" "public" {
  name    = "db.public"
  type    = "A"
  zone_id = aws_route53_zone.public.id
  records = [aws_db_instance.public.endpoint]
}

# Variables
variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "domain_suffix" {
  default = "example.com"
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  default     = "password123"
  sensitive   = true
}