provider "aws" {
  region = "us-west-2"
}

resource "aws_db_instance" "primary" {
  identifier           = "main-primary"
  instance_class       = "db.t3.micro"
  engine               = "mysql"
  username             = "admin"
  password             = "password"
  skip_final_snapshot  = true
}

resource "aws_db_instance" "replica-1" {
  identifier           = "main-replica-1"
  instance_class       = "db.t3.micro"
  engine               = "mysql"
  username             = "admin"
  password             = "password"
  skip_final_snapshot  = true
}

resource "aws_db_instance" "replica-2" {
  identifier           = "main-replica-2"
  instance_class       = "db.t3.micro"
  engine               = "mysql"
  username             = "admin"
  password             = "password"
  skip_final_snapshot  = true
}

resource "aws_route53_zone" "main" {
  name = "example.com."
}

resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "main.example.com."
  type    = "A"
  alias {
    name                   = aws_db_instance.primary.endpoint
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "replica-1" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "replica-1.example.com."
  type    = "A"
  alias {
    name                   = aws_db_instance.replica-1.endpoint
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "replica-2" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "replica-2.example.com."
  type    = "A"
  alias {
    name                   = aws_db_instance.replica-2.endpoint
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "weighted-routing-policy" {
  zone_id       = aws_route53_zone.main.zone_id
  name          = "main.example.com."
  type          = "CNAME"
  alias {
    name                   = aws_db_instance.primary.endpoint
    evaluate_target_health = false
  }
  weighted_routing_policy {
    weight = 50
    target {
      value = aws_route53_record.replica-1.name
    }
  }
}

resource "aws_route53_record" "weighted-routing-policy-replica-2" {
  zone_id       = aws_route53_zone.main.zone_id
  name          = "main.example.com."
  type          = "CNAME"
  alias {
    name                   = aws_db_instance.replica-2.endpoint
    evaluate_target_health = false
  }
  weighted_routing_policy {
    weight = 50
    target {
      value = aws_route53_record.replica-1.name
    }
  }
}