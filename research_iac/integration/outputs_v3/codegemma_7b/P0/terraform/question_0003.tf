provider "aws" {
  region = "us-west-1"
  alias = "main"
}

provider "aws" {
  region = "us-east-1"
  alias = "us-east"
}

provider "aws" {
  region = "eu-central-1"
  alias = "eu-central"
}

provider "aws" {
  region = "ap-southeast-1"
  alias = "ap-southeast"
}

resource "aws_db_instance" "primary" {
  # ...
}

resource "aws_db_instance" "replica_us_east" {
  # ...
}

resource "aws_db_instance" "replica_eu_central" {
  # ...
}

resource "aws_db_instance" "replica_ap_southeast" {
  # ...
}

resource "aws_route53_zone" "main" {
  # ...
}

resource "aws_route53_record_set" "weighted_routing" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"

  alias {
    name = aws_db_instance.primary.endpoint
    weight = 10
  }

  alias {
    name = aws_db_instance.replica_us_east.endpoint
    weight = 5
  }

  alias {
    name = aws_db_instance.replica_eu_central.endpoint
    weight = 5
  }

  alias {
    name = aws_db_instance.replica_ap_southeast.endpoint
    weight = 5
  }
}