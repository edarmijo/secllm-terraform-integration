provider "aws" {
  alias = "main"
  region = "us-west-1"
}

provider "aws" {
  alias = "us-east"
  region = "us-east-1"
}

provider "aws" {
  alias = "eu-central"
  region = "eu-central-1"
}

provider "aws" {
  alias = "ap-southeast"
  region = "ap-southeast-1"
}

resource "aws_db_instance" "primary" {
  provider = aws.main
  identifier = "main-db"
  instance_class = "db.t2.micro"
  engine = "mysql"
  username = "admin"
  password = "password"
}

resource "aws_db_instance" "replica_us_east" {
  provider = aws.us-east
  identifier = "replica-us-east-db"
  instance_class = "db.t2.micro"
  engine = "mysql"
  username = "admin"
  password = "password"
  replica_source_identifier = aws_db_instance.primary.id
}

resource "aws_db_instance" "replica_eu_central" {
  provider = aws.eu-central
  identifier = "replica-eu-central-db"
  instance_class = "db.t2.micro"
  engine = "mysql"
  username = "admin"
  password = "password"
  replica_source_identifier = aws_db_instance.primary.id
}

resource "aws_db_instance" "replica_ap_southeast" {
  provider = aws.ap-southeast
  identifier = "replica-ap-southeast-db"
  instance_class = "db.t2.micro"
  engine = "mysql"
  username = "admin"
  password = "password"
  replica_source_identifier = aws_db_instance.primary.id
}

resource "aws_route53_zone" "main" {
  provider = aws.main
  name     = "main.com."
}

resource "aws_route53_record" "primary" {
  provider = aws.main
  zone_id   = aws_route53_zone.main.zone_id
  name      = "primary.main.com."
  type      = "A"
  alias {
    name                   = aws_db_instance.primary.address
    zone_id                = aws_db_instance.primary.endpoint.split(".")[1]
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "replica_us_east" {
  provider = aws.us-east
  zone_id   = aws_route53_zone.main.zone_id
  name      = "replica-us-east.main.com."
  type      = "A"
  alias {
    name                   = aws_db_instance.replica_us_east.address
    zone_id                = aws_db_instance.replica_us_east.endpoint.split(".")[1]
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "replica_eu_central" {
  provider = aws.eu-central
  zone_id   = aws_route53_zone.main.zone_id
  name      = "replica-eu-central.main.com."
  type      = "A"
  alias {
    name                   = aws_db_instance.replica_eu_central.address
    zone_id                = aws_db_instance.replica_eu_central.endpoint.split(".")[1]
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "replica_ap_southeast" {
  provider = aws.ap-southeast
  zone_id   = aws_route53_zone.main.zone_id
  name      = "replica-ap-southeast.main.com."
  type      = "A"
  alias {
    name                   = aws_db_instance.replica_ap_southeast.address
    zone_id                = aws_db_instance.replica_ap_southeast.endpoint.split(".")[1]
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "weighted_routing_policy" {
  provider = aws.main
  zone_id   = aws_route53_zone.main.zone_id
  name      = "main.com."
  type      = "CNAME"
  weighted_routing_policy {
    weight = 10
    evaluation_location = "us-west-1"
    geo_location {
      country_code = "US"
      name         = "United States"
    }
    geo_location {
      country_code = "EU"
      name         = "Europe"
    }
    geo_location {
      country_code = "AS"
      name         = "Australia/Southeast Asia"
    }
  }
  alias {
    name                   = aws_db_instance.primary.address
    zone_id                = aws_db_instance.primary.endpoint.split(".")[1]
    evaluate_target_health = false
  }
}