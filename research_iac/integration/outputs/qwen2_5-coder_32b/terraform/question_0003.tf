provider "aws" {
  alias  = "main"
  region = "us-west-1"
}

provider "aws" {
  alias  = "us-east"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu-central"
  region = "eu-central-1"
}

provider "aws" {
  alias  = "ap-southeast"
  region = "ap-southeast-1"
}

resource "aws_iam_role" "route53_role" {
  name = "route53-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "route53.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_route53_zone" "main" {
  provider = aws.main
  name     = "main."
}

resource "aws_db_instance" "primary" {
  provider            = aws.main
  identifier          = "primary"
  instance_class      = "db.t2.micro"
  engine              = "mysql"
  allocated_storage   = 20
  username            = "admin"
  password            = "password"
  skip_final_snapshot = true
}

resource "aws_db_instance" "replica_us_east" {
  provider            = aws.us-east
  identifier          = "replica_us_east"
  instance_class      = "db.t2.micro"
  engine              = "mysql"
  allocated_storage   = 20
  username            = "admin"
  password            = "password"
  skip_final_snapshot = true
  replicate_source_db = aws_db_instance.primary.identifier
}

resource "aws_db_instance" "replica_eu_central" {
  provider            = aws.eu-central
  identifier          = "replica_eu_central"
  instance_class      = "db.t2.micro"
  engine              = "mysql"
  allocated_storage   = 20
  username            = "admin"
  password            = "password"
  skip_final_snapshot = true
  replicate_source_db = aws_db_instance.primary.identifier
}

resource "aws_db_instance" "replica_ap_southeast" {
  provider            = aws.ap-southeast
  identifier          = "replica_ap_southeast"
  instance_class      = "db.t2.micro"
  engine              = "mysql"
  allocated_storage   = 20
  username            = "admin"
  password            = "password"
  skip_final_snapshot = true
  replicate_source_db = aws_db_instance.primary.identifier
}

resource "aws_route53_record" "weighted_routing" {
  provider         = aws.main
  zone_id          = aws_route53_zone.main.zone_id
  name             = "db.main."
  type             = "CNAME"
  ttl              = 60

  weighted_records = [
    {
      resource_record = "${aws_db_instance.replica_us_east.address}"
      weight          = 10
    },
    {
      resource_record = "${aws_db_instance.replica_eu_central.address}"
      weight          = 10
    },
    {
      resource_record = "${aws_db_instance.replica_ap_southeast.address}"
      weight          = 10
    }
  ]
}