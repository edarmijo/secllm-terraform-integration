terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"
  alias  = "main"
}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east"
}

provider "aws" {
  region = "eu-central-1"
  alias  = "eu-central"
}

provider "aws" {
  region = "ap-southeast-1"
  alias  = "ap-southeast"
}

resource "aws_route53_zone" "main" {
  provider     = aws.main
  name         = "example.com"
  force_destroy = true
}

resource "aws_db_instance" "primary" {
  provider                 = aws.main
  allocated_storage        = 20
  engine                   = "mysql"
  instance_class           = "db.t3.micro"
  identifier               = "primary"
  name                     = "mydb"
  username                 = "admin"
  password                 = "password123"
  skip_final_snapshot      = true
}

resource "aws_db_instance" "replica_us_east" {
  provider                 = aws.us-east
  allocated_storage        = 20
  engine                   = "mysql"
  instance_class           = "db.t3.micro"
  identifier               = "replica-us-east"
  replicate_source_db      = aws_db_instance.primary.arn
}

resource "aws_db_instance" "replica_eu_central" {
  provider                 = aws.eu-central
  allocated_storage        = 20
  engine                   = "mysql"
  instance_class           = "db.t3.micro"
  identifier               = "replica-eu-central"
  replicate_source_db      = aws_db_instance.primary.arn
}

resource "aws_db_instance" "replica_ap_southeast" {
  provider                 = aws.ap-southeast
  allocated_storage        = 20
  engine                   = "mysql"
  instance_class           = "db.t3.micro"
  identifier               = "replica-ap-southeast"
  replicate_source_db      = aws_db_instance.primary.arn
}

resource "aws_route53_record" "weighted_routing" {
  provider = aws.main
  zone_id  = aws_route53_zone.main.zone_id
  name     = "db.example.com"
  type     = "CNAME"

  weighted_routing_policy {
    weight = 1
  }

  set_identifier = "us-east-1"
  value         = aws_db_instance.replica_us_east.address
}

resource "aws_route53_record" "weighted_routing_eu" {
  provider = aws.main
  zone_id  = aws_route53_zone.main.zone_id
  name     = "db.example.com"
  type     = "CNAME"

  weighted_routing_policy {
    weight = 1
  }

  set_identifier = "eu-central-1"
  value         = aws_db_instance.replica_eu_central.address
}

resource "aws_route53_record" "weighted_routing_ap" {
  provider = aws.main
  zone_id  = aws_route53_zone.main.zone_id
  name     = "db.example.com"
  type     = "CNAME"

  weighted_routing_policy {
    weight = 1
  }

  set_identifier = "ap-southeast-1"
  value         = aws_db_instance.replica_ap_southeast.address
}